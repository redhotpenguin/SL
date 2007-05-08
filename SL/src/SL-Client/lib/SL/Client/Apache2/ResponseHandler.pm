package SL::Client::Apache2::ResponseHandler;

use strict;
use warnings;

use Apache2::Const -compile => qw( OK SERVER_ERROR NOT_FOUND DECLINED
  REDIRECT LOG_DEBUG LOG_ERR LOG_INFO CONN_KEEPALIVE HTTP_BAD_REQUEST
  HTTP_UNAUTHORIZED );
use Apache2::Connection     ();
use Apache2::Log            ();
use Apache2::RequestRec     ();
use Apache2::RequestUtil    ();
use Apache2::RequestIO      ();
use Apache2::ServerRec      ();
use Apache2::ServerUtil		();
use Apache2::URI            ();
use APR::Table              ();
use HTTP::Headers           ();
use HTTP::Headers::Util     ();
use HTTP::Message           ();
use HTTP::Request           ();
use HTTP::Response          ();
use Data::Dumper            qw( Dumper );

use SL::Client::HTTP;

our %response_map = (
            200 => \&twohundred,
            404 => \&fourohfour,
            500 => \&bsod,
            400 => \&badrequest,
            401 => \&fourohone,
            302 => \&redirect,
            301 => \&redirect,
            304 => \&threeohfour,
            307 => \&redirect,
           );

sub handler {
    my $r   = shift;
    my $url = $r->pnotes('url');

    $r->log->debug("$$ PRH handler url $url");
    $r->log->debug("$$ Request is \n" . $r->the_request);
    $r->log->debug("$$ Request as string \n" . $r->as_string);
    $r->log->debug("$$ Unparsed uri is \n" . $r->unparsed_uri);

    my $response = make_request($r, $url);
    
    # Dispatch the response
    return $response_map{$response->code}->($r, $response);
}

sub make_request {
    my ($r, $url) = @_;
    my $proxy_host = $r->pnotes('proxy_host');
    my $proxy_port = $r->pnotes('proxy_port');

    # need to use an array to preserve multiple instances of a header 
    my @headers;
    $r->headers_in->do( sub { push(@headers, $_[0], $_[1]) });

    # make the request via the proxy
    my $response = SL::Client::HTTP->get(url => $url,
                                         host => $proxy_host,
                                         port => $proxy_port,
                                         headers => \@headers);
    return $response;
}

sub bsod {
    my $r        = shift;
    my $response = shift;

    $r->log->error("$$ Request returned 500, response ", Dumper($response));
    return Apache2::Const::SERVER_ERROR;
}

sub badrequest {
    my $r        = shift;
    my $response = shift;

    $r->log->error("$$ Request returned 400, response ", Dumper($response));
    return Apache2::Const::HTTP_BAD_REQUEST;
}

sub fourohfour {
    my $r        = shift;
    my $res	 = shift;

    # FIXME - set the proper headers out
    $r->log->debug("$$ Request returned 404, response ", Dumper($res));
    $r->status_line($res->status_line);
    my $content_type = $res->content_type;
    $r->content_type($content_type);
    _err_cookies_out($r, $res);
    $r->print($res->content);
    return Apache2::Const::OK;
}

sub fourohone {
    my $r        = shift;
    my $res = shift;
    
    # FIXME - set the proper headers out
    $r->log->error("$$ Request returned 401, response ", Dumper($res));
    $r->status_line($res->status_line);
    my $content_type = $res->content_type;
    $r->content_type($content_type);
    _err_cookies_out($r, $res);
    
    # method specific headers
    my @auth_headers = $res->header('www-authenticate');
    $r->log->debug("Auth headers are " . Dumper(\@auth_headers));
    $r->err_headers_out->add('www-authenticate' => $_) for @auth_headers;
    _add_x_headers($r, $res);

    return Apache2::Const::HTTP_UNAUTHORIZED;
}

sub _add_x_headers {
    my ($r, $res) = @_;
    my @x_header_names = grep { $_ =~ m{^x\-}i } 
      $res->headers->header_field_names;
    
    $r->log->debug("Found x-... headers: " . Dumper(\@x_header_names));
    foreach my $x_header ( @x_header_names ) {
        $r->err_headers_out->add($x_header => $res->header($x_header));
    }
    return 1;
}

sub redirect {
    my $r        = shift;
    my $response = shift;

    $r->log->info("$$ 302 redirect handler invoked");
    $r->log->debug("$$ headers: ", Dumper($response->headers));

    # set the status line
    $r->status_line($response->status_line);
    $r->log->debug("status line is " . $response->status_line);
    
    ## Handle the redirect for the client
    $r->headers_out->set('Location' => $response->header('location'));
    _err_cookies_out($r, $response);
    $r->log->debug("$$ Request: \n" . $r->as_string);
    return Apache2::Const::REDIRECT;
}

sub _err_cookies_out {
    my ($r, $response) = @_;
    if (my @cookies = $response->header('set-cookie')) {
        foreach my $cookie ( @cookies ) {
            $r->log->debug("Adding cookie to headers_out: $cookie");
            $r->err_headers_out->add('Set-Cookie' => $cookie);
        }
        $response->headers->remove_header('Set-Cookie');
    }
    return 1;
}
	
sub twohundred {
    my $r        = shift;
    my $response = shift;
    
    my $url = $r->pnotes('url');
    $r->log->info("$$ Request to $url returned 200");
    
    # set the status line
    $r->status_line($response->status_line);
    $r->log->debug("status line is " . $response->status_line);

    # This loops over the response headers and adds them to headers_out.
    # Override any headers with our own here
    my %headers;
    $r->headers_out->clear();

    # Handle the cookies first.  We'll get multiple headers for set-cookie
    # for example with sites with netflix.  We need to have a generic method
    # of dealing with headers that are returning multiple values per key,
    # we're covering the set-cookie header but I'm sure we're missing some
    # other headers that will bite us at some point, so FIXME TODO
    foreach my $cookie ( $response->header('set-cookie')) {
        $r->headers_out->add('Set-Cookie' => $cookie);
    }
    $response->headers->remove_header('Set-Cookie');
    
    # Create a hash with the HTTP::Response HTTP::Headers attributes
    $response->scan(sub { $headers{$_[0]} = $_[1]; });
    $r->log->debug("Response headers: " . Dumper(\%headers));
    
    ## Set the response content type from the request, preserving charset
    my $content_type = $response->header('content-type');
    $r->content_type($content_type);
    delete $headers{'Content-Type'};

    ## Content encoding
    #$r->content_encoding($response->header('content-encoding'));
    delete $headers{'Content-Encoding'};

    ## Content languages
    if (defined $response->header('content-language')) {
        $r->content_languages([$response->header('content-language')]);
        $r->log->debug("$$ content languages set to " . 
                       $response->header('content_language'));
        delete $headers{'Content-Language'};
    }

    delete $headers{'Client-Peer'};
    delete $headers{'Content-Encoding'};
	
    foreach my $key (keys %headers) {
        next if $key =~ m/^Client/; # skip HTTP::Response inserted headers
        $r->headers_out->set($key => $headers{$key});
    }

    # FIXME
    # this is not setting the Keep-Alive header at all for some reason
    $r->connection->keepalive(1);

    # maybe someday but not today
    $r->no_cache(1);

    $r->log->debug("$$ Request string before sending: \n" . $r->as_string);
    #$r->log->debug("$$ Response: \n" . $response_content);
    # rflush() flushes the headers to the client
    # thanks to gozer's mod_perl for speed presentation
    $r->rflush();

    # Print the response content
    $r->print($response->content);
    return Apache2::Const::OK;
}

1;
