package SL::Apache::Proxy::ResponseHandler;

use strict;
use warnings;

=head1 NAME

SL::Apache

=head1 DESCRIPTION

Does the request wrangling.

=head1 DEPENDENCIES

Mostly Apache2 and HTTP class based.

=cut

# mp core
use Apache2::Const -compile => qw( OK SERVER_ERROR NOT_FOUND DECLINED
  REDIRECT LOG_DEBUG LOG_ERR LOG_INFO CONN_KEEPALIVE HTTP_BAD_REQUEST
  HTTP_UNAUTHORIZED HTTP_SEE_OTHER HTTP_MOVED_PERMANENTLY DONE
  HTTP_NO_CONTENT HTTP_PARTIAL_CONTENT HTTP_NOT_MODIFIED );
use Apache2::Connection  ();
use Apache2::Log         ();
use Apache2::RequestRec  ();
use Apache2::RequestUtil ();
use Apache2::RequestIO   ();
use Apache2::Response    ();
use Apache2::ServerRec   ();
use Apache2::ServerUtil  ();
use Apache2::URI         ();
use Apache2::Filter      ();
use APR::Table           ();

# sl libraries
use SL::Config               ();
use SL::HTTP::Client         ();
use SL::Model::Proxy::Ad     ();

use SL::Subrequest           ();
use SL::RateLimit            ();
use SL::Model::Proxy::Router ();
use SL::Apache::Proxy        ();

# non core perl libs
use Encode           ();
use RHP::Timer       ();
use Compress::Zlib   ();
use Compress::Bzip2  ();
use URI::Escape      ();

our $Config;

BEGIN {
    $Config = SL::Config->new;
}

use constant NOOP_RESPONSE => $Config->sl_noop_response || 0;
use constant DEBUG         => $ENV{SL_DEBUG}            || 0;
use constant VERBOSE_DEBUG => $ENV{SL_VERBOSE_DEBUG}    || 0;
use constant TIMING        => $ENV{SL_TIMING}           || 0;
use constant REPLACE_PORT  => 8135;
use constant MAX_NONHTML   => 200 * 1024; # 50k

# unencoded http responses must be this big to get an ad
use constant MIN_CONTENT_LENGTH => $Config->sl_min_content_length || 2500;

our ( $TIMER, $REMOTE_TIMER );
if (TIMING) {
    $TIMER        = RHP::Timer->new();
    $REMOTE_TIMER = RHP::Timer->new();
}

require Data::Dumper if ( DEBUG or VERBOSE_DEBUG );

our $Cache              = SL::Cache->new( type => 'raw' );
our $RATE_LIMIT         = SL::RateLimit->new;
our $Subrequest = SL::Subrequest->new;

=head1 AD SERVING

We've got a number of different algorithms to serve the ad with the response.
Here's a list of them with a synopsis of each.

=over 4

=item C<munge_body>

This method puts the ad in a table data after the body tag.  Like so:
<html><body><table><tr><td>Buy stuff from us maing!!</td></tr></table>...

This works with pages that don't have stylesheets, but on pages with stylesheets
it doesn't work so well because the page content can cover up the ad.  This
was the first algorithm used for this project.

=item C<stacked>

This method actually puts a mini web page 'above' the content received from
the proxy server.  Like so:
<html><body><p>foofoobarbar</p><body></html>
<html><body>response from proxy...

I've only tested with firefox so at this point it's theoretical.  Don't know
if it plays nice with stylesheets either.

=item C<container>

The industrial strength, no nonsense solution.  So when working with pages
that use stylesheets (e.g. web 2.0 sites), this approach takes the post
<body> content of the proxy request, shoves it into a div container, pulls in
our stylesheet which defines the container, and plops the ad above the
container.  This (hopefully) insures that we don't fuck up the layout of the
site.  Like so:

Proxy request:  
 <html>
   <head>
     <title>sup maing</title>
     <link rel="stylesheet" href="/igotstyle.css" type="text/css" />
     <script type="text/javascript">
       do some scripty shit
     </script>
   </head>
   <body>
     <div id="originalstyle">
       <p>Hizzah!</p>
     </div>
   </body>
 </html>

After our filter:  ( --> indicates content added by filter )
 <html>
   <head>
     <title>sup maing</title>
     <link rel="stylesheet" href="/silverstyle.css" type="text/css" />
-->  <link rel="stylesheet" href="/igotstyle.css" type="text/css" />
     <script type="text/javascript">
       do some scripty shit
     </script>
   </head>
   <body>
-->  <div id="silverad">
-->    <p>We are in control.  Do not attempt to adjust your webpage.</p>
-->  </div>
-->  <div id="silverwrapper">
       <div id="originalstyle">
         <p>Hizzah!</p>
       /</div>
-->  </div>
   </body>
 </html>

The question at hand for container is 'will it work?'

=cut

sub handler {
    my $r = shift;

    return SL::Apache::Proxy->handler(__PACKAGE__, $r);
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



sub twoohfour {
    my ( $r, $res ) = @_;

    # status line 204 response
    $r->status( $res->code );

    # translate the headers from the remote response to the proxy response
    my $translated = SL::Model::Proxy->set_response_headers( $r, $res );

    # rflush() flushes the headers to the client
    # thanks to gozer's mod_perl for speed presentation
    $r->rflush();

    # no content sent for a 204
    return Apache2::Const::OK;
}

sub twoohsix {
    my ( $r, $res ) = @_;

    # set the status line here and I will beat you with a stick

    my $content_type = $res->content_type;
    $r->content_type($content_type) if $content_type;

    # translate the headers from the remote response to the proxy response
    my $translated = SL::Model::Proxy->set_response_headers( $r, $res );

    # rflush() flushes the headers to the client
    # thanks to gozer's mod_perl for speed presentation
    $r->rflush();

    $r->print( $res->content );

    # we send a 200 here so don't change this or mess with the status line!
    return Apache2::Const::OK;
}

sub bsod {
    my ( $r, $res ) = @_;

    # setup response
    $r->status( $res->code );

    my $content_type = $res->content_type;
    $r->content_type($content_type) if $content_type;

    # translate the headers from the remote response to the proxy response
    my $translated = SL::Model::Proxy->set_response_headers( $r, $res );

    # rflush() flushes the headers to the client
    # thanks to gozer's mod_perl for speed presentation
    $r->rflush();

    $r->print( $res->content );

    return Apache2::Const::OK;
}

sub threeohone {
    my ( $r, $res ) = @_;

    my $content_type = $res->content_type;
    $r->content_type($content_type) if $content_type;

    # translate the headers from the remote response to the proxy response
    my $translated = SL::Model::Proxy->set_response_headers( $r, $res );

    # do not change this line
    return Apache2::Const::HTTP_MOVED_PERMANENTLY;
}

# 302, 303, 307
sub redirect {
    my ( $r, $res ) = @_;

    # translate the headers from the remote response to the proxy response
    my $translated = SL::Model::Proxy->set_response_headers( $r, $res );

    # do not change this line
    return Apache2::Const::REDIRECT;
}

sub threeohfour {
    my ( $r, $res ) = @_;

    # set the status line
    $r->status( $res->code );

    # translate the headers from the remote response to the proxy response
    my $translated = SL::Model::Proxy->set_response_headers( $r, $res );

    # do not change this line
    return Apache2::Const::OK;
}

sub _non_html_two_hundred {
    my ( $r, $response ) = @_;

    $r->log->debug("$$ non html 200, length " . length($response->decoded_content)) if DEBUG;

    my $url = $r->construct_url( $r->unparsed_uri );

    if ( $response->decoded_content && (length( $response->decoded_content ) < MAX_NONHTML )) {

        $r->log->debug("$$ sending response directly ") if DEBUG;

        my $response_content_ref = \$response->decoded_content;

        # set the status line
        $r->status_line( $response->status_line );
        $r->log->debug( "$$ status line is " . $response->status_line )
          if DEBUG;

        # set the response headers
        my $set_ok =
          SL::Model::Proxy->set_twohundred_response_headers( $r, $response, $response_content_ref );

        if (VERBOSE_DEBUG) {
            $r->log->debug( "$$ Reponse headers to client " . $r->as_string );
#            $r->log->debug( "$$ Response content: " . $$response_content_ref );
        }

        # rflush() flushes the headers to the client
        # thanks to gozer's mod_perl for speed presentation
        $r->rflush();

        my $bytes_sent = $r->print($$response_content_ref);
        $r->log->debug("$$ bytes sent: $bytes_sent") if DEBUG;

        return Apache2::Const::OK;

    }

    # else send to perlbal to reproxy
    $r->headers_out->add( 'X-REPROXY-URL' => $url );
    $r->set_handlers( PerlLogHandler => undef );

    return Apache2::Const::DONE;
}


sub twohundred {
    my ( $r, $response ) = @_;

    my $url = $r->pnotes('url');

    return _non_html_two_hundred($r, $response) if !$response->is_html;

    # Cache the content_type, some misnomers in this section re: html
    $Cache->add_known_html( $url => $response->content_type );

    # code above is not a bottleneck
    ####################################

    ################################
    # the request rate limiter
    $TIMER->start('rate_limiter') if TIMING;
    my $user_id = join( '|', $r->pnotes('hash_mac'), $r->pnotes('ua') );
    my $is_toofast = $RATE_LIMIT->check_violation($user_id) || 0;
    $r->log->debug("$$ ===> $url check_violation: $is_toofast") if VERBOSE_DEBUG;
    $r->log->info(
        sprintf( "timer $$ %s %s %d %s %f", @{ $TIMER->checkpoint } ) )
      if TIMING;

    ##############################
    # serve an ad if this is not a sub-request of an
    # ad-serving page, and it's not too soon after a previous ad was served
    my $response_content_ref;
    my $ad_served;
    if ((	( not $is_toofast )
        and ( not $Subrequest->is_subrequest( url => $url ) ) ) )
    {

        # put an ad in the response
		my $router = $r->pnotes('router');
		if ($router->{persistent}) {
			$response_content_ref = _generate_response( $r, $response );

		    if ( !$response_content_ref ) {

			    # we could not serve an ad on this page for some reason
				$r->log->debug(
					"ad not served, _generate_response failed url $url") if DEBUG;
			} else {

				# we served an ad, note the ad-serving time for the rate-limiter
				$ad_served = 1;
				$RATE_LIMIT->record_ad_serve($user_id);
			}
		}
    }    # end 'if ('
    else {

        # this is not html or its compressed, etc
        $r->log->debug("$$ ad not served, using existing content") if DEBUG;
    }

    # settings for ad not served
    $response_content_ref = \$response->decoded_content unless $ad_served;

    ##############################################
    # grab the links from the page and stash them
    $TIMER->start('collect_subrequests') if TIMING;
    my $subreqs_ref = $Subrequest->collect_subrequests(
        content_ref => $response_content_ref,
        base_url    => $url,
    );

    # checkpoint for collect_subrequuests
    $r->log->info(
        sprintf( "timer $$ %s %s %d %s %f", @{ $TIMER->checkpoint } ) )
      if TIMING;

    ###########################################
    # we replace the links even on pages that we don't serve ads on to
    # speed things up
    if ( defined $subreqs_ref ) {

        # setting in place, replace the links
        my $ok = $Subrequest->replace_subrequests(
            {
                port        => REPLACE_PORT,
                subreq_ref  => [ @{$subreqs_ref->{subreqs}},
                                 @{$subreqs_ref->{jslinks}} ],
                content_ref => $response_content_ref,
            }
        );
        $r->log->info("$$ could not replace subrequests for url $url")
          unless $ok;
    }

    # affiliate replacement
    $TIMER->start('affiliate replace') if TIMING;

    if ($subreqs_ref->{ads} && @{$subreqs_ref->{ads}} ) {
        my $ads_ref = $subreqs_ref->{ads};

        # $r->log->error("subreq ref " . Data::Dumper::Dumper($subreqs_ref->{ads}));
        my $replace_adslots = SL::AdParser->parse_all($subreqs_ref->{ads});
		#$r->log->error("slots are " . Data::Dumper::Dumper($replace_adslots));

        if ($replace_adslots) {

            $r->log->debug("$$ starting ad swap") if DEBUG;
            SL::Model::Proxy::Ad->swap( $response_content_ref,
                  $replace_adslots, $r->pnotes('router'));

        }
    }

    $r->log->info(
        sprintf( "timer $$ %s %s %d %s %f", @{ $TIMER->checkpoint } ) )
      if TIMING;

    # set the status line
    $r->status_line( $response->status_line );
    $r->log->debug( "$$ status line is " . $response->status_line ) if DEBUG;

    # set the response headers
    my $set_ok = SL::Model::Proxy->set_twohundred_response_headers( $r, $response, $response_content_ref );

    if (VERBOSE_DEBUG) {
        $r->log->debug( "$$ Reponse headers to client " . $r->as_string );
        $r->log->debug( "$$ Response content: " . $$response_content_ref );
    }

    # rflush() flushes the headers to the client
    # thanks to gozer's mod_perl for speed presentation
    $r->rflush();

    # Print the response content
    $TIMER->start('print_response') if TIMING;

    my $bytes_sent = $r->print($$response_content_ref);
    $r->log->debug("$$ bytes sent: $bytes_sent") if DEBUG;

    # checkpoint
    $r->log->info(
        sprintf( "$bytes_sent bytes sent, timer $$ %s %s %d %s %f",
            @{ $TIMER->checkpoint } )
    ) if TIMING;

    return Apache2::Const::OK;
}



=item C<_generate_response( $r, $response )>

Puts the ad in the response

=cut

sub _generate_response {
    my ( $r, $response ) = @_;

    # yes this is ugly but it helps for testing
    return $response->decoded_content if NOOP_RESPONSE;

    my $url     = $r->pnotes('url');
    my $ua      = $r->pnotes('ua');
    my $referer = $r->pnotes('referer');

    # grab the decoded content
    my $decoded_content        = $response->decoded_content;
    my $content_needs_encoding = 1;

    unless ( defined $decoded_content ) {

        # hmmm, in some cases decoded_content is null so we use regular content
        # https://www.redhotpenguin.com/bugzilla/show_bug.cgi?id=424
        $decoded_content = $response->content;

        # don't try to re-encode it in this case
        $content_needs_encoding = 0;
    }

    # check to make sure that the content can accept an ad
    $r->log->debug( "$$ content length is " . length($decoded_content) )
      if DEBUG;

    unless ( length($decoded_content) > MIN_CONTENT_LENGTH ) {
        $r->log->debug(
            "$$ content too small for ad: " . length($decoded_content) )
          if DEBUG;
        $r->log->debug("$$ small content is \n$decoded_content\n")
          if VERBOSE_DEBUG;

        ## TODO - mark for perlbal next time
        return;
    }

    ##############################################################
    # grab an ad
    $TIMER->start('random_ad') if TIMING;


    my %ad_args = (
        ip           => $r->connection->remote_ip,
        url          => $url,
        router_id    => $r->pnotes('router_id'),
        user         => $r->pnotes('hash_mac'),
        ua           => $ua,
        device_guess => $r->pnotes('device_guess'),
    );

    if ($r->pnotes('device_guess')) {
        $ad_args{device_guess} = $r->pnotes('device_guess');
    }

	$r->log->debug("$$ ad args: " . Data::Dumper::Dumper(\%ad_args)) if DEBUG;

    my (
        $ad_zone_id, $ad_content_ref, $css_url_ref,
        $js_url_ref, $head_html_ref,  $ad_size_id,
    ) = SL::Model::Proxy::Ad->random( \%ad_args );

    # checkpoint random ad
    $r->log->info(
        sprintf( "timer $$ %s %s %d %s %f", @{ $TIMER->checkpoint } ) )
      if TIMING;

    $r->log->debug("$$ Ad content is \n$$ad_content_ref\n") if VERBOSE_DEBUG;

    unless ($ad_content_ref) {
        $r->log->error("$$ Hmm, we didn't get an ad for url $url");
        return;
    }

    ########################################
    # put the ad in the page
    $TIMER->start('container insertion') if TIMING;
    my $ok = SL::Model::Proxy::Ad::container(
        $css_url_ref,      $js_url_ref,     $head_html_ref,
        \$decoded_content, $ad_content_ref
    );

    # checkpoint
    $r->log->info(
        sprintf( "timer $$ %s %s %d %s %f", @{ $TIMER->checkpoint } ) )
      if TIMING;

    unless ($ok) {

        # TODO - mark url to be skipped next time
        $r->log->debug("$$ could not insert adzone $ad_zone_id into url $url") if DEBUG;
        return;
    }

    # We've made it this far so we're looking good
    $r->log->debug("$$ Ad inserted url $url; referer: $referer;") if DEBUG;

    $r->log->debug("$$ Munged response is \n $decoded_content")
      if VERBOSE_DEBUG;

    # Log the ad view later
    $r->pnotes( ad_zone_id => $ad_zone_id );

    # re-encode content if needed
    if ($content_needs_encoding) {
        my $charset = SL::Model::Proxy->response_charset($response);

        # don't need to worry about errors - this content came from
        # Encode::decode via HTTP::Message::decoded_content, so as
        # long as we don't start putting in non-ASCII ad content we
        # should have no problems round-tripping.  If an error does
        # occur the character will be replaced with a "subchar"
        # specific to the encoding.
        $decoded_content = Encode::encode( $charset, $decoded_content );
    }

    return \$decoded_content;
}

1;
