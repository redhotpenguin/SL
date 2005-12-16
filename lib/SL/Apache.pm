package SL::Apache;

use strict;
use warnings;

=head1 NAME

SL::Apache

=head1 DESCRIPTION

Does the request wrangling.

=head1 DEPENDENCIES

Mostly Apache2 and HTTP class based.

=cut

use Apache2::Const -compile => qw( OK SERVER_ERROR NOT_FOUND DECLINED REDIRECT);
use Apache2::Cookie     ();
use Apache2::Log        ();
use Apache2::Request    ();
use Apache2::RequestRec ();
use Apache2::RequestIO  ();
use Apache2::URI        ();
use Data::Dumper qw( Dumper );
use HTTP::Headers  ();
use HTTP::Message  ();
use HTTP::Request  ();
use HTTP::Response ();
use SL::UserAgent  ();
use SL::Ad         ();

=head1 METHODS

=over 4

=item C<handler($r)>

=cut

sub _add_headers {
    my ( $proxy_req, $cookies ) = @_;

    ## FIXME - I whine about warnings in the error log
    {
        no warnings;
        $cookies->do(
            sub {
                my ( $key, $value ) = @_;
                $proxy_req->header( $key => $value );
            }
        );
    }
    return $proxy_req;
}

sub handler {
    my $r = shift;

    my $url = $r->construct_url( $r->unparsed_uri);
    $r->log->info( "Process $$ handling request for ", $url );

    my $content_type = $r->pnotes('content_type');
    
    my $response = _make_request( $r );
    my $response_content;
    # Handle the response on a case basis depending on response code
    #
    if ( $response->code == 500 ) {
        $r->log->error( "Request returned 500 ",         $response->code );
        $r->log->error( "Response from remote server: ", Dumper($response) );
        return Apache2::Const::SERVER_ERROR;
    }
    elsif ( $response->code == 404 ) {
        $r->log->error( "Request returned 404 ",         $response->code );
        $r->log->error( "Response from remote server: ", Dumper($response) );
        return Apache2::Const::NOT_FOUND;
    }
    elsif ( $response->code == 302 or $response->code == 301 ) {
        $r->log->debug("Request returned ", $response->code);
        $r->log->debug("Response: ", Data::Dumper::Dumper($response));
        $r->status_line( $response->code() . ' ' . $response->message() );
        $response->scan( sub { $r->err_headers_out->add(@_); } );
        $r->headers_out->set( Location => $response->header('location') );
        return Apache2::Const::REDIRECT;
    }
    elsif ( $response->code == 200 ) {
        $r->log->debug("Request returned 200 ");
        $r->log->debug("Response:  ", Data::Dumper::Dumper($response));
        
        # Cache the content_type
        SL::Cache::stash( $url => $response->content_type );
        if ( not SL::Util::not_html( $response->content_type ) ) {
            $response_content = _generate_response( $r, $response );
        } else {
            $response_content = $response->content;
        }
    }
    else {
        $r->log->error( "Unsuccessful proxy request, code ", $response->code );
        $r->log->error( "Response from remote server: ", Dumper($response) );
        return Apache2::Const::SERVER_ERROR;
    }

    # Set the response content type
    #
    my $type = $response->header('content-type');
    $r->content_type($type);

    # Baaaaah - need to figure out what this stuff actually does, if we need it
    $r->status_line( $response->code() . ' ' . $response->message() );
    $response->scan( sub { $r->err_headers_out->add(@_); } );

    # Print the response
    #
    $r->print($response_content);
    return Apache2::Const::OK;
}

sub _make_request {
    my $r = shift;
    # Rebuild the query string for the remote request
    my $req = Apache2::Request->new($r);

    # Grab the cookies
    my $cookies = Apache2::Cookie->fetch($r);

    my $ua = SL::UserAgent->new($r);

    # Construct the url for the proxy request with any ?args=this&args=that
    my $url = $r->construct_url( $r->unparsed_uri );

    ######################
    # Create a request object
    my $proxy_req = HTTP::Request->new( $r->method(), $url );
    if ($cookies) {
        $proxy_req = _add_headers( $proxy_req, $cookies );
    }

    ######################################
    ##  Do this schiznit for a post request
    #
    if ( $r->method eq 'POST' ) {
        $r->log->debug("Building content for POST request");
        my $body = $req->param;
        my $content;
        foreach my $key ( keys %$body ) {
            my $value = $body->get($key);
            $r->log->info("Key is $key, value is $value");
            if ($content) {
                $content .= "&";
            }
            $content .= "$key=$value";
        }
        $proxy_req->content($content);
    }

    $r->log->debug( "Request to remote server: ", Dumper($proxy_req) );

    # Make the request to the remote server
    #
    my $response = $ua->request($proxy_req);

    # Handle browser redirects instead of passing those back to the client
    if ( $response->code == 200 ) {
        if ( my $redirect = _browser_redirect( $response ) ) {
            $r->log->debug("Executing browser redirect to $redirect");
            $proxy_req->uri( $redirect );
            $response = $ua->request( $proxy_req );
            unless ( $response->code == 200 ) {
                return $response->code;
            }
        }
    }
    return $response;
}

sub _browser_redirect { 
    my $response = shift;
   
    # Examine the response content and return the browser redirect url if found
    if ( my ($redirect) = $response->content =~ m/
        (?-xism:<meta\s+http-equiv\s*?=\s*?"Refresh"\s*?content\s*?=\s*?"?0"?\;
        \s*?url\s*?=\s*?(http:\/\/\w+\.[^\"|^\>|\s]+))/xmsi ) {
        return $redirect;
    }
}

=item C<r($r)>

Puts the ad in the response

=cut

sub _generate_response {
    my ( $r, $response ) = @_;

    # Skip ad insertion if stylesheets present

    if ( $response->content =~ m/\.css/xms ) {
        $r->log->info("Skipping ad insertion");
        return $response->content;
    }

    # Fix for sites like google, yahoo who send the content encoded UTF-8 et al
    #
    my $response_content = $response->decoded_content();

    # Put the ad right after the <body*> tag
    my $ad = SL::Ad->random_as_string($r);
    $response_content =~ s{^(.*)<body([^>]*)>}{$1<body$2>$ad}isxm;

    # Log an error if the ad insertion fails
    unless ( grep( $ad, $response_content ) ) {
        $r->log->error("ALERT:  could not embed ad in response");
    }

    $r->log->info("Ad inserted to response");

    return $response_content;
}

1;
