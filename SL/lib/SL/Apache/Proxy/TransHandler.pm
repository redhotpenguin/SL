package SL::Apache::Proxy::TransHandler;

use strict;
use warnings;

=head1 NAME
 
SL::Apache::TransHandler

=head1 SYNOPSIS

=cut

use SL::Model      ();
use SL::Model::URL ();
use Time::HiRes    ();

our $EXT_REGEX;
our $UA_REGEX;
our $VERBOSE_DEBUG = 0;

BEGIN {
    require Regexp::Assemble;

    ## Extension based matching
    my @extensions = qw(
      ad avi bz2 css doc exe fla gif gz ico jpeg jpg js pdf png ppt rar sit
      rss tgz txt wmv vob xpi zip );

    $EXT_REGEX = Regexp::Assemble->new;
    $EXT_REGEX->add(@extensions);
    print STDERR "Regex for static content match is ", $EXT_REGEX->re, "\n\n"
      if $DEBUG;
}

use Apache2::Const -compile =>
  qw( OK SERVER_ERROR NOT_FOUND DECLINED CONN_KEEPALIVE DONE);
use Apache2::Connection     ();
use Apache2::ConnectionUtil ();
use Apache2::RequestRec     ();
use Apache2::RequestUtil    ();
use Apache2::ServerRec      ();
use Apache2::ServerUtil     ();
use Data::Dumper qw( Dumper );
use SL::Cache;
use SL::Util;

sub proxy_request {
    my $r = shift;
    if ($r->dir_config('SLProxy') eq 'perlbal') {
        return &perlbal($r);
    }
    elsif ($r->dir_config('SLProxy') eq 'mod_proxy') {
        return &mod_proxy($r);
    }
}

sub static_content_uri {
    my $url = shift;
    if ($url =~ m{\.(?:$EXT_REGEX)$}i) {
        return 1;
    }
}

sub not_a_main_request {
    my $r = shift;

    my $c      = $r->connection;
    my $rlinks = $c->pnotes('rlinks');
    unless (defined $rlinks) {

        # this is a new connection so scan just return and grab the links later
        $r->log->debug("$$ RLINKS undefined");
        return;
    }
    $r->log->debug("Rlinks are " . join(', ', @{$rlinks}));

    my $referer = $r->pnotes('referer');
    if (grep { $_ =~ m/$referer/ } @{$r->connection->pnotes("rlinks")}) {
        $r->log->debug("This request referer matches rlinks");
        return;
    }
}

sub handler {
    my $r = shift;

    my $url = $r->construct_url($r->unparsed_uri);
    my $referer = $r->headers_in->{'referer'} || 'no_referer';

    $r->pnotes('url'     => $url);
    $r->pnotes('referer' => $referer);
    my $ua = $r->pnotes('ua');

    $r->log->debug(
        sprintf(
"$$ PerlTransHandler Request for url $url, user-agent $ua, referer $referer"
        )
    );

    # first check that a database handle is available
    my $dbh = SL::Model->connect();
    unless ($dbh) {
        $r->log->error("Database has gone away, sending to mod_proxy");
        return &proxy_request($r);
    }

    # allow /sl_secret_blacklist_button to pass through
    if ($url =~ m!/sl_secret_blacklist_button$!) {
        return Apache2::Const::OK;
    }

    # allow /sl_secret_ping_button to pass through
    if ($url =~ m!/sl_secret_ping_button$!) {
        return Apache2::Const::DONE;
    }

    if (user_blacklisted($r, $dbh)) {
        return &proxy_request($r);
    }

    if (url_blacklisted($url)) {
        return &proxy_request($r);
    }

    ## Handle non-browsers that use port 80
    #
    if (_not_a_browser($r)) {
        return &proxy_request($r);
    }

    ## check for browser subrequests - UNDER CONSTRUCTION
    if (not_a_main_request($r)) {
        return &proxy_request($r);
    }

    if ($r->method ne 'GET') {
        return &proxy_request($r);
    }

    if ($r->method eq 'GET') {

        ## Static content
        #
        if (static_content_uri($url)) {
            $r->log->info("$$ Url $url static content extension, proxying");
            return &proxy_request($r);
        }

        ## Check the cache for a static content match
        #
        if (my $content_type = SL::Cache::grab($url)) {

            $r->log->info("$$ SL::Cache hit for url $url, type $content_type");

            if (SL::Util::not_html($content_type)) {
                ## Cache returned static content
                #
                $r->log->info("$$ Proxying static $url, type $content_type");
                return &proxy_request($r);
            }
            else {

                # Cache returned dynamic html
                #
                $r->log->info("$$ SL::Cache $url HTML type $content_type");
                $r->pnotes('content_type' => $content_type);
            }
        }
    }
    $r->log->info("EndTranshandler");
}

sub user_blacklisted {
    my ($r, $dbh) = @_;

    my $user_id = join("|",
                       $r->connection->remote_ip, $r->pnotes('ua'),
                       $r->construct_server());

    my $sth =
      $dbh->prepare(
                 "SELECT count(user_id) FROM user_blacklist WHERE user_id = ?");
    $sth->bind_param(1, $user_id);
    $sth->execute;
    my $ary_ref = $sth->fetchrow_arrayref;
    return 1 if $ary_ref->[0] > 0;
    return;
}

sub url_blacklisted {
    my $url = shift;

    my $blacklist_regex = SL::Model::URL->blacklist_regex;
    return 1 if ($url =~ m{$blacklist_regex});
}

# extract this to a utility library or something
sub _not_a_browser {
    my $r = shift;

    # all browsers start with Mozilla, at least in apache
    if (substr($r->pnotes('ua'), 0, 7) eq 'Mozilla') {
        return;
    }

    $r->log->debug("$$ This is not a browser: " . $r->pnotes('ua'));
    return 1;
}

sub mod_proxy {
    my $r = shift;

    ## Don't change this next line even if you think you should
    #
    my $url = $r->construct_url;

    ## Use mod_proxy to do the proxying
    #
    $r->log->info("$$ mod_proxy handling request for $url");
    $r->uri($url);

    $r->filename("proxy:$url");
    $r->handler('proxy-server');
    $r->proxyreq(1);
    return Apache2::Const::DECLINED;
}

sub perlbal {
    my $r = shift;

    ##########
    # Use perlbal to do the proxying
    $r->log->info("Using perlbal to reproxy request");
    my $uri = $r->construct_url($r->unparsed_uri);
    $r->headers_out->add('X-REPROXY-URL' => $r->construct_url);
    return Apache2::Const::DONE;
}

1;
