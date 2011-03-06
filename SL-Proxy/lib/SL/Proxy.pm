package SL::Proxy;

use strict;
use warnings;

our $VERSION = 0.03;

use base 'Apache2::Proxy';

use Apache2::Const -compile => qw( OK DONE );
  
use Config::SL       ();

our $Cache;
our $Config = Config::SL->new;

use constant DEBUG         => $ENV{SL_DEBUG}   || 0;
use constant VERBOSE_DEBUG => $ENV{SL_VERBOSE_DEBUG} || 0;
use constant TIMING        => $ENV{SL_TIMING}        || 0;

sub handler {
    my ( $class, $r ) = @_;

    $r->log->error("$$ $class handler active, sending to Apache2::Proxy");
    return $class->SUPER::handler($r);

=cut

    # Build the request headers
    my $headers = $class->get_request_headers($r);

    # start the clock
    $TIMER->start('make_remote_request') if TIMING;

    my $url = $r->pnotes('url');
    my %get = (
        headers      => $headers,
        url          => $url,
        headers_only => 1,
    );


        $get{host} = $ip;
    }

    $r->log->debug("making request " . Dumper(\%get)) if DEBUG;

    # Make the request to the remote server
    my $response = eval { SL::HTTP::Client->get( \%get ); };

    # socket timeout, give em the crazy page
    if ($@) {
        $r->log->error("$class $$ error fetching $url : $@") if DEBUG;
        return &crazypage($r);    # haha this page is kwazy!
    }

    $r->log->debug("$class $$ request to $url complete") if DEBUG;

    # no response means html too big
    # send it to perlbal to reproxy
    unless ($response) {

        $r->log->debug("$class $$ response non html or too big") if DEBUG;
        $r->headers_out->add( 'X-REPROXY-URL' => $url );
        return Apache2::Const::OK;
    }

    $r->log->debug( "$$ Response headers from url $url proxy request code\n" 
          . "code: "
          . $response->code . "\n"
          . Dumper( $response->headers ) )
      if VERBOSE_DEBUG;

    # checkpoint make remote request
    $r->log->info(
        sprintf( "timer $$ %s %s %d %s %f", @{ $TIMER->checkpoint } ) )
      if TIMING;

    # Dispatch the response
    my $sub = $Response_map{ $response->code };
    unless ( defined $sub ) {
        $r->log->error(
            sprintf(
                "No handler for response code %d, url %s, ua %s",
                $response->code, $url, $r->pnotes('ua')
            )
        );
        $sub = $Response_map{'404'};
    }

    $r->log->debug(
        sprintf(
            "$$ Request returned %d response: %s",
            $response->code, Dumper( $response->decoded_content ),
        )
    ) if VERBOSE_DEBUG;

    no strict 'refs';
    return $class->$sub( $r, $response );
=cut
}

# this page handles invalid urls, we run ads there

sub crazypage {
    my $r = shift;

    $r->content_type('text/html');
    $r->print( "<html><body><h2>Sorry the url "
          . $r->pnotes('url')
          . ' is not a valid hostname, please try again.</h2></body></html>' );
    return Apache2::Const::OK;
}

sub bsod {
    my ( $class, $r, $res ) = @_;

    # setup response
    $r->status( $res->code );

    my $content_type = $res->content_type;
    $r->content_type($content_type) if $content_type;

    # translate the headers from the remote response to the proxy response
    my $translated = $class->set_response_headers( $r, $res );

    # rflush() flushes the headers to the client
    # thanks to gozer's mod_perl for speed presentation
    $r->rflush();

    $r->print( $res->content );

    return Apache2::Const::OK;
}

# the big dog
sub twohundred {
    my ( $class, $r, $response, $subref ) = @_;

    $r->log->error("$$ sub two_hundred super called");

    return $class->SUPER::twohundred($r, $response, $subref );
    my $url = $r->pnotes('url');

    if ($response->is_html) {

        $Cache->add_known_html( $url => $response->content_type );

    } else {

        $Cache->add_known_not_html( $url => $response->content_type );
    }

    $r->log->debug( "$$ 200 for $url, length "
          . length( $response->decoded_content )
          . " bytes" )
      if DEBUG;

    my $response_content_ref = \$response->decoded_content;

    # set the status line
    $r->status_line( $response->status_line );
    $r->log->debug( "$$ status line is " . $response->status_line )
      if DEBUG;

    # set the response headers
    my $set_ok =
      $class->set_twohundred_response_headers( $r, $response,
        $response_content_ref );

    if (VERBOSE_DEBUG) {
        $r->log->debug( "$$ Reponse headers to client " . $r->as_string );
        $r->log->debug( "$$ Response content: " . $$response_content_ref );
    }

    # rflush() flushes the headers to the client
    # thanks to gozer's mod_perl for speed presentation
    $r->rflush();

    my $bytes_sent = $r->print($$response_content_ref);
    $r->log->debug("$$ bytes sent: $bytes_sent") if DEBUG;

    return Apache2::Const::DONE;
}

1;

__END__
