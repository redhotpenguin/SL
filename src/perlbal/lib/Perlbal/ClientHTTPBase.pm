######################################################################
# Common HTTP functionality for ClientProxy and ClientHTTP
# possible states:
#   reading_headers (initial state, then follows one of two paths)
#     wait_backend, backend_req_sent, wait_res, xfer_res, draining_res
#     wait_stat, wait_open, xfer_disk
# both paths can then go into persist_wait, which means they're waiting
# for another request from the user
#
# Copyright 2004, Danga Interactice, Inc.
# Copyright 2005, Six Apart, Ltd.

package Perlbal::ClientHTTPBase;
use strict;
use warnings;
no  warnings qw(deprecated);

use Sys::Syscall;
use base "Perlbal::Socket";
use HTTP::Date ();
use fields ('service',             # Perlbal::Service object
            'replacement_uri',     # URI to send instead of the one requested; this is used
                                   # to instruct _serve_request to send an index file instead
                                   # of trying to serve a directory and failing
            'scratch',             # extra storage; plugins can use it if they want

            # reproxy support
            'reproxy_file',        # filename the backend told us to start opening
            'reproxy_file_size',   # size of file, once we stat() it
            'reproxy_fh',          # if needed, IO::Handle of fd
            'reproxy_file_offset', # how much we've sent from the file.

            'requests',            # number of requests this object has performed for the user

            # service selector parent
            'selector_svc',        # the original service from which we came
            );

use Errno qw( EPIPE ECONNRESET );
use POSIX ();

# ghetto hard-coding.  should let siteadmin define or something.
# maybe console/config command:  AddMime <ext> <mime-type>  (apache-style?)
our $MimeType = {qw(
                    css  text/css
                    doc  application/msword
                    gif  image/gif
                    htm  text/html
                    html text/html
                    jpg  image/jpeg
                    js   application/x-javascript
                    mp3  audio/mpeg
                    mpg  video/mpeg
                    png  image/png
                    tif   image/tiff
                    tiff  image/tiff
                    torrent  application/x-bittorrent
                    txt   text/plain
                    zip   application/zip
)};

# ClientHTTPBase
sub new {
    my ($class, $service, $sock, $selector_svc) = @_;

    my $self = $class;
    $self = fields::new($class) unless ref $self;
    $self->SUPER::new($sock);       # init base fields

    $self->{service}         = $service;
    $self->{replacement_uri} = undef;
    $self->{headers_string}  = '';
    $self->{requests}        = 0;
    $self->{scratch}         = {};
    $self->{selector_svc}    = $selector_svc;

    $self->state('reading_headers');

    bless $self, ref $class || $class;
    $self->watch_read(1);
    return $self;
}

sub close {
    my Perlbal::ClientHTTPBase $self = shift;

    # don't close twice
    return if $self->{closed};

    # close the file we were reproxying, if any
    CORE::close($self->{reproxy_fh}) if $self->{reproxy_fh};

    # now pass up the line
    $self->SUPER::close(@_);
}

# given the response headers we just got, and considering our request
# headers, determine if we should be sending keep-alive header
# information back to the client
sub setup_keepalive {
    my Perlbal::ClientHTTPBase $self = $_[0];
    print "ClientHTTPBase::setup_keepalive($self)\n" if Perlbal::DEBUG >= 2;

    # now get the headers we're using
    my Perlbal::HTTPHeaders $reshd = $_[1];
    my Perlbal::HTTPHeaders $rqhd = $self->{req_headers};

    # for now, we enforce outgoing HTTP 1.0
    $reshd->set_version("1.0");

    # if we came in via a selector service, that's whose settings
    # we respect for persist_client
    my $svc = $self->{selector_svc} || $self->{service};
    my $persist_client = $svc->{persist_client} || 0;
    print "  service's persist_client = $persist_client\n" if Perlbal::DEBUG >= 3;

    # do keep alive if they sent content-length or it's a head request
    my $do_keepalive = $persist_client && $rqhd->req_keep_alive($reshd);
    if ($do_keepalive) {
        print "  doing keep-alive to client\n" if Perlbal::DEBUG >= 3;
        my $timeout = $self->max_idle_time;
        $reshd->header('Connection', 'keep-alive');
        $reshd->header('Keep-Alive', $timeout ? "timeout=$timeout, max=100" : undef);
    } else {
        print "  doing connection: close\n" if Perlbal::DEBUG >= 3;
        # FIXME: we don't necessarily want to set connection to close,
        # but really set a space-separated list of tokens which are
        # specific to the connection.  "close" and "keep-alive" are
        # just special.
        $reshd->header('Connection', 'close');
        $reshd->header('Keep-Alive', undef);
    }
}

# called when we've finished writing everything to a client and we need
# to reset our state for another request.  returns 1 to mean that we should
# support persistence, 0 means we're discarding this connection.
sub http_response_sent {
    my Perlbal::ClientHTTPBase $self = $_[0];

    # close if we're supposed to
    if (
        ! defined $self->{res_headers} ||
        ! $self->{res_headers}->res_keep_alive($self->{req_headers}) ||
        $self->{do_die}
        )
    {
        # do a final read so we don't have unread_data_waiting and RST
        # the connection.  IE and others send an extra \r\n after POSTs
        my $dummy = $self->read(5);

        # close if we have no response headers or they say to close
        $self->close("no_keep_alive");
        return 0;
    }

    # if they just did a POST, set the flag that says we might expect
    # an unadvertised \r\n coming from some browsers.  Old Netscape
    # 4.x did this on all POSTs, and Firefox/Safari do it on
    # XmlHttpRequest POSTs.
    if ($self->{req_headers}->request_method eq "POST") {
        $self->{ditch_leading_rn} = 1;
    }

    # now since we're doing persistence, uncork so the last packet goes.
    # we will recork when we're processing a new request.
    $self->tcp_cork(0);

    # prepare!
    $self->{replacement_uri} = undef;
    $self->{headers_string} = '';
    $self->{req_headers} = undef;
    $self->{res_headers} = undef;
    $self->{reproxy_fh} = undef;
    $self->{reproxy_file} = undef;
    $self->{reproxy_file_size} = 0;
    $self->{reproxy_file_offset} = 0;
    $self->{read_buf} = [];
    $self->{read_ahead} = 0;
    $self->{read_size} = 0;
    $self->{scratch} = {};

    # reset state
    $self->state('persist_wait');

    if (my $selector_svc = $self->{selector_svc}) {
        $selector_svc->return_to_base($self);
    }

    # NOTE: because we only speak 1.0 to clients they can't have
    # pipeline in a read that we haven't read yet.
    $self->watch_read(1);
    $self->watch_write(0);
    return 1;
}

sub reproxy_fh {
    my Perlbal::ClientHTTPBase $self = shift;

    # setter
    if (@_) {
        my ($fh, $size) = @_;
        $self->state('xfer_disk');
        $self->{reproxy_fh} = $fh;
        $self->{reproxy_file_offset} = 0;
        $self->{reproxy_file_size} = $size;
        # call hook that we're reproxying a file
        return $fh if $self->{service}->run_hook("start_send_file", $self);
        # turn on writes (the hook might not have wanted us to)
        $self->watch_write(1);
        return $fh;
    }

    return $self->{reproxy_fh};
}

sub event_read {
    my Perlbal::ClientHTTPBase $self = shift;

    # see if we have headers?
    die "Shouldn't get here!  This is an abstract base class, pretty much, except in the case of the 'selector' role."
        if $self->{req_headers};

    my $hd = $self->read_request_headers;
    return unless $hd;

    return if $self->{service}->run_hook('start_http_request', $self);

    # we must stop watching for events now, otherwise if there's
    # PUT/POST overflow, it'll be sent to ClientHTTPBase, which can't
    # handle it yet.  must wait for the selector (which has as much
    # time as it wants) to route as to our subclass, which can then
    # renable reads.
    $self->watch_read(0);

    # now that we have headers, it's time to tell the selector
    # plugin that it's time for it to select which real service to
    # use
    my $selector = $self->{'service'}->selector();
    return $self->_simple_response(500, "No service selector configured.")
        unless ref $selector eq "CODE";
    $selector->($self);
}

# client is ready for more of its file.  so sendfile some more to it.
# (called by event_write when we're actually in this mode)
sub event_write_reproxy_fh {
    my Perlbal::ClientHTTPBase $self = shift;

    my $to_send = $self->{reproxy_file_size} - $self->{reproxy_file_offset};
    $self->tcp_cork(1) if $self->{reproxy_file_offset} == 0;

    my $sent = Perlbal::Socket::sendfile($self->{fd},
                                         fileno($self->{reproxy_fh}),
                                         $to_send);
    print "REPROXY Sent: $sent\n" if Perlbal::DEBUG >= 2;

    if ($sent < 0) {
        return $self->close("epipe")     if $! == EPIPE;
        return $self->close("connreset") if $! == ECONNRESET;
        print STDERR "Error w/ sendfile: $!\n";
        $self->close('sendfile_error');
        return;
    }
    $self->{reproxy_file_offset} += $sent;

    if ($sent >= $to_send) {
        # close the sendfile fd
        CORE::close($self->{reproxy_fh});

        $self->{reproxy_fh} = undef;
        $self->http_response_sent;
    }
}

sub event_write {
    my Perlbal::ClientHTTPBase $self = shift;

    # Any HTTP client is considered alive if it's writable
    # if it's not writable for 30 seconds, we kill it.
    # subclasses can decide what's appropriate for timeout.
    $self->{alive_time} = time;

    # if we're sending a filehandle, go do some more sendfile:
    if ($self->{reproxy_fh}) {
        $self->event_write_reproxy_fh;
        return;
    }

    # otherwise just kick-start our write buffer.
    if ($self->write(undef)) {
        # we've written all data in the queue, so stop waiting for
        # write notifications:
        print "All writing done to $self\n" if Perlbal::DEBUG >= 2;
        $self->watch_write(0);
    }
}

# this gets called when a "web" service is serving a file locally.
sub _serve_request {
    my Perlbal::ClientHTTPBase $self = shift;
    my Perlbal::HTTPHeaders $hd = shift;

    my $rm = $hd->request_method;
    unless ($rm eq "HEAD" || $rm eq "GET") {
        return $self->_simple_response(403, "Unimplemented method");
    }

    my $uri = Perlbal::Util::durl($self->{replacement_uri} || $hd->request_uri);

    # chop off the query string
    $uri =~ s/\?.*//;

    # don't allow directory traversal
    if ($uri =~ /\.\./ || $uri !~ m!^/!) {
        return $self->_simple_response(403, "Bogus URL");
    }

    my Perlbal::Service $svc = $self->{service};

    # start_serve_request hook
    return 1 if $self->{service}->run_hook('start_serve_request', $self, \$uri);

    return $self->_simple_response(500, "Docroot unconfigured")
        unless $svc->{docroot};

    my $file = $svc->{docroot} . $uri;

    # update state, since we're now waiting on stat
    $self->state('wait_stat');

    Perlbal::AIO::aio_stat($file, sub {
        # client's gone anyway
        return if $self->{closed};
        return $self->_simple_response(404) unless -e _;

        my $lastmod = HTTP::Date::time2str((stat(_))[9]);
        my $not_mod = ($hd->header("If-Modified-Since") || "") eq $lastmod && -f _;

        my $res;
        my $not_satisfiable = 0;
        my $size = -s _ if -f _;

        my ($status, $range_start, $range_end) = $hd->range($size);

        if ($not_mod) {
            $res = $self->{res_headers} = Perlbal::HTTPHeaders->new_response(304);
        } elsif ($status == 416) {
            $res = $self->{res_headers} = Perlbal::HTTPHeaders->new_response(416);
            $res->header("Content-Range", $size ? "bytes */$size" : "*");
            $res->header("Content-Length", 0);
            $not_satisfiable = 1;
        } elsif ($status == 206) {
            # partial content
            $res = $self->{res_headers} = Perlbal::HTTPHeaders->new_response(206);
        } else {
            $res = $self->{res_headers} = Perlbal::HTTPHeaders->new_response(200);
        }

        # now set whether this is keep-alive or not
        $res->header("Date", HTTP::Date::time2str());
        $res->header("Server", "Perlbal");
        $res->header("Last-Modified", $lastmod);

        if (-f _) {
            # advertise that we support byte range requests
            $res->header("Accept-Ranges", "bytes");

            unless ($not_mod || $not_satisfiable) {
                my ($ext) = ($file =~ /\.(\w+)$/);
                $res->header("Content-Type",
                             (defined $ext && exists $MimeType->{$ext}) ? $MimeType->{$ext} : "text/plain");

                unless ($status == 206) {
                    $res->header("Content-Length", $size);
                } else {
                    $res->header("Content-Range", "bytes $range_start-$range_end/$size");
                    $res->header("Content-Length", $range_end - $range_start + 1);
                }
            }

            # has to happen after content-length is set to work:
            $self->setup_keepalive($res);

            if ($rm eq "HEAD" || $not_mod || $not_satisfiable) {
                # we can return already, since we know the size
                $self->tcp_cork(1);
                $self->state('xfer_resp');
                $self->write($res->to_string_ref);
                $self->write(sub { $self->http_response_sent; });
                return;
            }

            # state update
            $self->state('wait_open');

            Perlbal::AIO::aio_open($file, 0, 0, sub {
                my $rp_fh = shift;

                # if client's gone, just close filehandle and abort
                if ($self->{closed}) {
                    CORE::close($rp_fh) if $rp_fh;
                    return;
                }

                # handle errors
                if (! $rp_fh) {
                    # couldn't open the file we had already successfully stat'ed.
                    # FIXME: do 500 vs. 404 vs whatever based on $!
                    return $self->close('aio_open_failure');
                }

                $self->state('xfer_disk');
                $self->tcp_cork(1);  # cork writes to self
                $self->write($res->to_string_ref);

                # seek if partial content
                if ($status == 206) {
                    sysseek($rp_fh, $range_start, &POSIX::SEEK_SET);
                    $size = $range_end - $range_start + 1;
                }

                $self->reproxy_fh($rp_fh, $size);
            });

        } elsif (-d _) {
            $self->try_index_files($hd, $res, $uri);
        }
    });
}

sub try_index_files {
    my Perlbal::ClientHTTPBase $self = shift;
    my ($hd, $res, $uri, $filepos) = @_;

    # make sure this starts at 0 initially, and fail if it's past the end
    $filepos ||= 0;
    if ($filepos >= scalar(@{$self->{service}->{index_files} || []})) {
        unless ($self->{service}->{dirindexing}) {
            # just inform them that listing is disabled
            $self->_simple_response(200, "Directory listing disabled");
            return;
        }

        # open the directory and create an index
        my $body = "";
        my $file = $self->{service}->{docroot} . $uri;

        $res->header("Content-Type", "text/html");
        opendir(D, $file);
        foreach my $de (sort readdir(D)) {
            if (-d "$file/$de") {
                $body .= "<b><a href='$de/'>$de</a></b><br />\n";
            } else {
                $body .= "<a href='$de'>$de</a><br />\n";
            }
        }
        closedir(D);

        $res->header("Content-Length", length($body));
        $self->setup_keepalive($res);

        $self->state('xfer_resp');
        $self->tcp_cork(1);  # cork writes to self
        $self->write($res->to_string_ref);
        $self->write(\$body);
        $self->write(sub { $self->http_response_sent; });
        return;
    }

    # construct the file path we need to check
    my $file = $self->{service}->{index_files}->[$filepos];
    my $fullpath = $self->{service}->{docroot} . $uri . '/' . $file;

    # now see if it exists
    Perlbal::AIO::aio_stat($fullpath, sub {
        return if $self->{closed};
        return $self->try_index_files($hd, $res, $uri, $filepos + 1) unless -f _;

        # at this point the file exists, so we just want to serve it
        $self->{replacement_uri} = $uri . '/' . $file;
        return $self->_serve_request($hd);
    });
}

sub _simple_response {
    my Perlbal::ClientHTTPBase $self = shift;
    my ($code, $msg) = @_;  # or bodyref

    my $res = $self->{res_headers} = Perlbal::HTTPHeaders->new_response($code);
    $res->header("Content-Type", "text/html");

    my $body;
    unless ($code == 204) {
        my $en = $res->http_code_english;
        $body = "<h1>$code" . ($en ? " - $en" : "") . "</h1>\n";
        $body .= $msg if $msg;
        $res->header('Content-Length', length($body));
    }

    $self->setup_keepalive($res);

    $self->state('xfer_resp');
    $self->tcp_cork(1);  # cork writes to self
    $self->write($res->to_string_ref);
    if (defined $body) {
        unless ($self->{req_headers} && $self->{req_headers}->request_method eq 'HEAD') {
            # don't write body for head requests
            $self->write(\$body);
        }
    }
    $self->write(sub { $self->http_response_sent; });
    return 1;
}


sub send_response {
    my Perlbal::ClientHTTPBase $self = shift;

    $self->watch_read(0);
    $self->watch_write(1);
    return $self->_simple_response(@_);
}

# method that sends a 500 to the user but logs it and any extra information
# we have about the error in question
sub system_error {
    my Perlbal::ClientHTTPBase $self = shift;
    my ($msg, $info) = @_;

    # log to syslog
    Perlbal::log('warning', "system error: $msg ($info)");

    # and return a 500
    return $self->send_response(500, $msg);
}

# FIXME: let this be configurable?
sub max_idle_time { 30; }

sub event_err {  my $self = shift; $self->close('error'); }
sub event_hup {  my $self = shift; $self->close('hup'); }

sub as_string {
    my Perlbal::ClientHTTPBase $self = shift;

    my $ret = $self->SUPER::as_string;
    my $name = $self->{sock} ? getsockname($self->{sock}) : undef;
    my $lport = $name ? (Socket::sockaddr_in($name))[0] : undef;
    $ret .= ": localport=$lport" if $lport;
    $ret .= "; reqs=$self->{requests}";
    $ret .= "; $self->{state}";

    my $hd = $self->{req_headers};
    if (defined $hd) {
        my $host = $hd->header('Host') || 'unknown';
        $ret .= "; http://$host" . $hd->request_uri;
    }

    return $ret;
}

1;

# Local Variables:
# mode: perl
# c-basic-indent: 4
# indent-tabs-mode: nil
# End:
