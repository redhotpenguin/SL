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

use Apache2::Const -compile => qw( OK SERVER_ERROR NOT_FOUND DECLINED
  REDIRECT LOG_DEBUG LOG_ERR LOG_INFO CONN_KEEPALIVE HTTP_BAD_REQUEST
  HTTP_UNAUTHORIZED HTTP_SEE_OTHER HTTP_MOVED_PERMANENTLY
  HTTP_NO_CONTENT HTTP_PARTIAL_CONTENT HTTP_NOT_MODIFIED );
use Apache2::Connection      ();
use Apache2::Log             ();
use Apache2::RequestRec      ();
use Apache2::RequestUtil     ();
use Apache2::RequestIO       ();
use Apache2::Response        ();
use Apache2::ServerRec       ();
use Apache2::ServerUtil      ();
use Apache2::URI             ();
use Apache2::Filter          ();
use APR::Table               ();

use SL::HTTP::Client ();
use SL::Model::Ad            ();
use SL::Cache                ();
use SL::Cache::Subrequest    ();
use SL::Cache::RateLimit     ();
use SL::Model::Proxy::Router ();
use Encode                   ();
use RHP::Timer               ();
use Regexp::Assemble         ();
use Compress::Zlib           ();
use Compress::Bzip2          ();
use URI::Escape              ();

use SL::Config;

our $CONFIG;

BEGIN {
    $CONFIG = SL::Config->new;
}
use constant GOOGLE_AD_ID  => $CONFIG->sl_google_ad_id;
use constant NOOP_RESPONSE => $CONFIG->sl_noop_response || 0;
use constant SL_XHEADER    => $CONFIG->sl_xheader || 0;

use constant DEBUG         => $ENV{SL_DEBUG}         || 0;
use constant VERBOSE_DEBUG => $ENV{SL_VERBOSE_DEBUG} || 0;
use constant TIMING        => $ENV{SL_TIMING}        || 0;

use constant REPLACE_PORT  => 8135;

use constant MIN_CONTENT_LENGTH => $CONFIG->sl_min_content_length || 2500;


my ( $TIMER, $REMOTE_TIMER );
if (TIMING) {
    $TIMER        = RHP::Timer->new();
    $REMOTE_TIMER = RHP::Timer->new();
}

if ( DEBUG or VERBOSE_DEBUG ) {
    require Data::Dumper;
}

our %response_map = (
    200 => 'twohundred',
    204 => 'twoohfour',
    206 => 'twoohsix',
    301 => 'threeohone',
    302 => 'redirect',
    303 => 'threeohthree',
    304 => 'threeohfour',
    307 => 'redirect',
    500 => 'bsod',
    503 => 'bsod',
    400 => 'badrequest',
    401 => 'fourohone',
    403 => 'fourohthree',
    404 => 'fourohfour',
);

our $CACHE              = SL::Cache->new( type => 'raw' );
our $RATE_LIMIT         = SL::Cache::RateLimit->new;
our $SUBREQUEST_TRACKER = SL::Cache::Subrequest->new;

use SL::Page::Cache;

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

our $SKIPS;

BEGIN {
    my @skips = qw( framset adwords.google.com
      MM_executeFlashDetection );

    push @skips, 'Ads by Goo';
    $SKIPS = Regexp::Assemble->new->add(@skips)->re;
    print STDERR "Regex for content insertion skips ", $SKIPS, "\n" if DEBUG;
}

sub _build_request_headers {
    my $r = shift;

    my %headers;
    $r->headers_in->do(
        sub {
            my $k = shift;
            my $v = shift;

            # skip sl headers
            return 1 if substr( lc($k), 0, 4 ) eq 'x-sl';

            # skip connection or keep alive headers
            return 1 if $k =~ m/^keep-alive/i;
            return 1 if $k =~ m/^connection/i;

            # skip perlbal headers
            return 1 if substr( lc($k), 0, 11 ) eq 'x-forwarded';
            return 1 if substr( lc($k), 0, 7 )  eq 'x-proxy';

            # pass this header onto the remote request
            $headers{$k} = $v;

            return 1;    # don't remove me
        }
    );

    # work around clients which don't support compression
    if ( !exists $headers{'Accept-Encoding'} ) {
        $r->log->debug( "$$ client DOES NOT support compression "
              . Data::Dumper::Dumper( \%headers ) )
          if DEBUG;

        # set default outgoing compression headers
        $headers{'Accept-Encoding'} = 'gzip, deflate';
    }
    else {
        $r->log->debug(
            "$$ client supports compression " . $headers{'Accept-Encoding'} )
          if DEBUG;
        $r->pnotes( client_supports_compression => $headers{'Accept-Encoding'} );
    }

    $r->log->debug(
        "$$ proxy request headers " . Data::Dumper::Dumper( \%headers ) )
      if DEBUG;

    return \%headers;
}

sub handler {
    my $r = shift;

    # Build the request headers
    my $headers = _build_request_headers($r);

    # the code above is not a bottleneck
    # start the clock
    $TIMER->start('make_remote_request') if TIMING;

    # Make the request to the remote server
    my $response = eval {
      SL::HTTP::Client->get({
         headers => $headers,
         url     => $r->pnotes('url'),
      });
    };

    if ($@) {
        $r->log->info("$$ error fetching url " . $r->pnotes('url'));
        return &crazypage($r); # haha this page is kwazy!
    }

    $r->log->debug(
        "$$ Response headers from proxy request",
        Data::Dumper::Dumper( $response->headers )
      )
      if DEBUG;

    # checkpoint make remote request
    $r->log->info(
        sprintf( "timer $$ %s %s %d %s %f", @{ $TIMER->checkpoint } ) )
      if TIMING;

    # Dispatch the response
    my $sub = $response_map{ $response->code };
    unless ( defined $sub ) {
        $r->log->error(
            sprintf(
                "No handler for response code %d, url %s, ua %s",
                $response->code, $r->pnotes('url'), $r->pnotes('ua')
            )
        );
        $sub = $response_map{'404'};
    }
    no strict 'refs';
    $r->log->debug( "$$ Response code " . $response->code ) if DEBUG;
    return $sub->( $r, $response );
}

# this page handles invalid urls, we run ads there

sub crazypage {
    my $r = shift;

    $r->content_type('text/html');
    $r->print("<html><body><h2>Sorry the url " . $r->pnotes('url') .
        ' is not a valid hostname, please try again.</h2></body></html>');
    return Apache2::Const::OK;
}

sub _translate_headers {
    my ( $r, $res ) = @_;

    # clear the current headers
    $r->headers_out->clear();

    # first the cookies
    if ( my @cookies = $res->header('set-cookie') ) {
        foreach my $cookie (@cookies) {
            $r->log->debug(
                sprintf( "err_headers_out add cookie %s", $cookie ) )
              if VERBOSE_DEBUG;

            $r->err_headers_out->add( 'Set-Cookie' => $cookie );

            # and remove it from the response headers
            $res->headers->remove_header('Set-Cookie');
        }
    }

    # auth headers
    if ( my @auth_headers = $res->header('www-authenticate') ) {

        $r->log->debug(
            "Auth headers are " . Data::Dumper::Dumper( \@auth_headers ) )
          if DEBUG;

        $r->err_headers_out->add( 'www-authenticate' => $_ ) for @auth_headers;

        # remove from response
        $res->headers->remove_header('www-authenticate');
    }

    # Create a hash with the remaining HTTP::Response HTTP::Headers attributes
    my %headers;
    $res->scan( sub { $headers{ $_[0] } = $_[1]; } );

    # now output the headers to the $r->headers_out->set
    foreach my $key ( keys %headers ) {
        next if $key =~ m/^Client/;    # skip HTTP::Response inserted headers

        # some headers have an unecessary newline appended so chomp the value
        chomp( $headers{$key} );

        # not sure why chomp doesn't fix this
        if ( $headers{$key} =~ m/\n/ ) {
            $headers{$key} =~ s/\n/ /g;
        }

        $r->log->debug(
            sprintf(
                "Setting key %s, value %s to headers",
                $key, $headers{$key}
            )
          )
          if VERBOSE_DEBUG;

        $r->headers_out->set( $key => $headers{$key} );
    }

    # set the server header
    $r->log->debug( "$$ server header is " . $headers{Server} ) if DEBUG;
    $r->server->add_version_component( $headers{Server} || 'sl' );
    return 1;
}

sub twoohfour {
    my ( $r, $res ) = @_;

    $r->log->debug( "$$ Request returned 204 response ",
        Data::Dumper::Dumper($res) )
      if VERBOSE_DEBUG;

    # status line 204 response
    $r->status( $res->code );

    # translate the headers from the remote response to the proxy response
    my $translated = _translate_headers( $r, $res );
    $r->log->error(
        sprintf(
            "header translation error \$r: %s, \$res %s",
            $r->as_string, Data::Dumper::Dumper($res)
        )
      )
      unless $translated;

    # rflush() flushes the headers to the client
    # thanks to gozer's mod_perl for speed presentation
    $r->rflush();

    # no content sent for a 204
    return Apache2::Const::OK;
}

sub twoohsix {
    my ( $r, $res ) = @_;

    $r->log->debug( "$$ Request returned 206 response ",
        Data::Dumper::Dumper($res) )
      if VERBOSE_DEBUG;

    my $content_type = $res->content_type;
    $r->content_type($content_type) if $content_type;

    # translate the headers from the remote response to the proxy response
    my $translated = _translate_headers( $r, $res );
    $r->log->error(
        sprintf(
            "$$ header translation error \$r: %s, \$res %s",
            $r->as_string, Data::Dumper::Dumper($res)
        )
      )
      unless $translated;

    # rflush() flushes the headers to the client
    # thanks to gozer's mod_perl for speed presentation
    $r->rflush();

    $r->print( $res->content );

    # we send a 200 here so don't change this or mess with the status line!
    return Apache2::Const::OK;
}

sub bsod {
    my ( $r, $res ) = @_;

    $r->log->debug( "$$ Request returned 500, response ",
        Data::Dumper::Dumper($res) )
      if VERBOSE_DEBUG;

    # setup response
    $r->status( $res->code );

    my $content_type = $res->content_type;
    $r->content_type($content_type) if $content_type;

    # translate the headers from the remote response to the proxy response
    my $translated = _translate_headers( $r, $res );

    # rflush() flushes the headers to the client
    # thanks to gozer's mod_perl for speed presentation

    $r->rflush();
    $r->print( $res->content );
    return Apache2::Const::OK;
}

sub badrequest {
    my ( $r, $res ) = @_;

    $r->log->debug( "$$ Request returned 400, response ",
        Data::Dumper::Dumper($res) )
      if VERBOSE_DEBUG;

    # setup response
    $r->status( $res->code );

    my $content_type = $res->content_type;
    $r->content_type($content_type) if $content_type;

    # translate the headers from the remote response to the proxy response
    my $translated = _translate_headers( $r, $res );

    # rflush() flushes the headers to the client
    # thanks to gozer's mod_perl for speed presentation
    $r->rflush();

    # send the response (400 in status line)
    $r->print( $res->content );
    return Apache2::Const::OK;
}

sub fourohone {
    my ( $r, $res ) = @_;

    $r->log->debug( "$$ Request returned 401, auth headers: ",
        Data::Dumper::Dumper( $res->header('www-authenticate') ) )
      if DEBUG;

    # setup response
    $r->status( $res->code );

    my $content_type = $res->content_type;
    $r->content_type($content_type) if $content_type;

    my $translated = _translate_headers( $r, $res );

    # rflush() flushes the headers to the client
    # thanks to gozer's mod_perl for speed presentation
    $r->rflush();

    # print the custom response content, and return OK (401 in status_line)
    $r->print( $res->content );
    return Apache2::Const::OK;
}

sub fourohthree {
    my ( $r, $res ) = @_;

    $r->log->debug( "$$ Request returned 403, response ",
        Data::Dumper::Dumper($res) )
      if VERBOSE_DEBUG;

    # set the status
    $r->status( $res->code );

    my $content_type = $res->content_type;
    $r->content_type($content_type) if $content_type;

    my $translated = _translate_headers( $r, $res );

    # rflush() flushes the headers to the client
    # thanks to gozer's mod_perl for speed presentation
    $r->rflush();

    # print the custom response content, and return OK (401 in status_line)
    $r->print( $res->content );
    return Apache2::Const::OK;
}

sub fourohfour {
    my ( $r, $res ) = @_;

    $r->log->debug( "$$ Request returned 404, response ",
        Data::Dumper::Dumper($res) )
      if VERBOSE_DEBUG;

    # setup response
    $r->status( $res->code );

    my $content_type = $res->content_type;
    $r->content_type($content_type) if $content_type;

    my $translated = _translate_headers( $r, $res );

    # rflush() flushes the headers to the client
    # thanks to gozer's mod_perl for speed presentation
    $r->rflush();

    # send the response (404 in status line)
    $r->print( $res->content );
    return Apache2::Const::OK;
}

sub threeohone {
    my ( $r, $res ) = @_;

    $r->log->debug(
        sprintf(
            "$$ status line %s, response: %s",
            $res->status_line, Data::Dumper::Dumper($res)
        )
      )
      if VERBOSE_DEBUG;

    # set the status line
    #$r->status($res->code);
    $r->log->debug( "$$ status line is " . $res->status_line ) if DEBUG;

    my $content_type = $res->content_type;
    $r->content_type($content_type) if $content_type;

    # translate the headers from the remote response to the proxy response
    my $translated = _translate_headers( $r, $res );
    $r->log->error(
        sprintf(
            "$$ header translation error \$r: %s, \b$res %s",
            $r->as_string, Data::Dumper::Dumper($res)
        )
      )
      unless $translated;

    # rflush() flushes the headers to the client
    # thanks to gozer's mod_perl for speed presentation
    #$r->rflush();

    $r->log->debug( "$$ Request: \n" . $r->as_string ) if VERBOSE_DEBUG;

    # do not change this line
    return Apache2::Const::HTTP_MOVED_PERMANENTLY;
}

sub redirect {
    my ( $r, $res ) = @_;

    $r->log->debug(
        sprintf(
            "$$ status line %s, response: %s",
            $res->status_line, Data::Dumper::Dumper($res)
        )
    ) if DEBUG;

    # set the status line
    #$r->status($res->code);
    $r->log->debug( "status line is " . $res->status_line ) if DEBUG;

    # translate the headers from the remote response to the proxy response
    my $translated = _translate_headers( $r, $res );

    # rflush breaks things, do not change this!
    # $r->rflush();

    $r->log->error(
        sprintf(
            "header translation error \$r: %s, \$res %s",
            $r->as_string, Data::Dumper::Dumper($res)
        )
      )
      unless $translated;

    $r->log->debug( "$$ Request: \n" . $r->as_string ) if VERBOSE_DEBUG;

    # do not change this line
    return Apache2::Const::REDIRECT;
}

# same as a 302 just different status line and constants
sub threeohthree {
    my ( $r, $res ) = @_;

    # set the status line
    #$r->status($res->code);
    $r->log->debug( "status line is " . $res->status_line ) if DEBUG;

    # translate the headers from the remote response to the proxy response
    my $translated = _translate_headers( $r, $res );

    # rflush breaks things, do not change this!
    # $r->rflush();

    $r->log->error(
        sprintf(
            "header translation error \$r: %s, \$res %s",
            $r->as_string, Data::Dumper::Dumper($res)
        )
      )
      unless $translated;

    $r->log->debug( "$$ Request: \n" . $r->as_string ) if VERBOSE_DEBUG;

    # do not change this line
    return Apache2::Const::REDIRECT;
}

# same as a 302 just different status line and constants
sub threeohfour {
    my ( $r, $res ) = @_;

    # set the status line
    $r->status($res->code);
    $r->log->debug( "status line is " . $res->status_line ) if DEBUG;

    # translate the headers from the remote response to the proxy response
    my $translated = _translate_headers( $r, $res );

    # rflush breaks things, do not change this!
    # $r->rflush();

    $r->log->error(
        sprintf(
            "header translation error \$r: %s, \$res %s",
            $r->as_string, Data::Dumper::Dumper($res)
        )
      )
      unless $translated;

    $r->log->debug( "$$ Request: \n" . $r->as_string ) if VERBOSE_DEBUG;

    # do not change this line
    return Apache2::Const::OK;
}

sub _non_html_two_hundred {
    my ($r, $res) = @_;

    # set the status
    $r->status( $res->code );

    my $content_type = $res->content_type;
    $r->content_type($content_type) if $content_type;

    my $translated = _translate_headers( $r, $res );

    $r->rflush();

    $r->print( $res->content );

    return Apache2::Const::OK;
}

sub _set_response_headers {
    my ($r, $response, $response_content_ref) = @_;

    # This loops over the response headers and adds them to headers_out.
    # Override any headers with our own here
    my %headers;
    $r->headers_out->clear();

    # Handle the cookies first.  We'll get multiple headers for set-cookie
    # for example with sites with netflix.  We need to have a generic method
    # of dealing with headers that are returning multiple values per key,
    # we're covering the set-cookie header but I'm sure we're missing some
    # other headers that will bite us at some point, so FIXME TODO
    foreach my $cookie ( $response->header('set-cookie') ) {
        $r->headers_out->add( 'Set-Cookie' => $cookie );
    }
    $response->headers->remove_header('Set-Cookie');

    # Create a hash with the HTTP::Response HTTP::Headers attributes
    $response->scan( sub { $headers{ $_[0] } = $_[1]; } );
    $r->log->debug(
        sprintf( "Response headers: %s", Data::Dumper::Dumper( \%headers ) ) )
      if DEBUG;

    ## Set the response content type from the request, preserving charset
    my $content_type = $response->header('content-type');
    $r->content_type( $headers{'Content-Type'} || '' );
    delete $headers{'Content-Type'};

    #############################
    ## Content languages
    if ( defined $headers{'content-language'} ) {
        $r->content_languages( [ $response->header('content-language') ] );
        $r->log->debug( "$$ content languages set to "
              . $response->header('content_language') )
          if DEBUG;
        delete $headers{'Content-Language'};
    }

    ##################
    # content_encoding
    # do not mess with this next section unless you like pain
    my $encoding;
    if ( $r->pnotes('client_supports_compression') ) {

        $r->log->debug("$$ client supports compression: " . $r->pnotes('client_supports_compression')) if DEBUG;

        my @h = map { $_->[0] } HTTP::Headers::Util::split_header_words( $r->pnotes('client_supports_compression'));
        $r->log->debug("$$ header words are " . join(',', @h)) if DEBUG;

        # use the first acceptable compression, ordered by
        if ( grep { $_ eq 'x-bzip2' } @h ) {

            $response_content_ref = Compress::Bzip2::compress($$response_content_ref);
            $encoding = 'x-bzip2';

        } elsif ( ( grep { $_ eq 'gzip' } @h ) ||
                  ( grep { $_ eq 'x-gzip' } @h ) ) { # some parts lifted from HTTP::Message

            # need a copy for memgzip, see HTTP::Message notes
            my $gzipped = eval { Compress::Zlib::memGzip($response_content_ref); };
			if ($gzipped && !$@) {
	            $$response_content_ref = $gzipped;
	            $encoding = 'gzip';
			}
        } elsif ( grep { $_ eq 'deflate' } @h ) {

            my $copy = $$response_content_ref;
            $$response_content_ref = Compress::Zlib::compress($copy);
            $encoding = 'deflate';

        } else {
            $r->log->error("$$ unknown content-encoding encountered:  " . join(',', @h));
        }
    }

    if ($encoding) {
        $r->log->debug("$$ setting content encoding to $encoding") if DEBUG;
        $r->content_encoding($encoding);
        delete $headers{'Transfer-Encoding'};    # don't want to be chunked here
    }
    delete $headers{'Content-Encoding'};

    ###########################
    # set the content length to the uncompressed content length
    $r->set_content_length( length($$response_content_ref) );
    delete $headers{'Content-Length'};

    ##########################################
    # this is for any additional headers, usually site specific
    foreach my $key ( keys %headers ) {

        # we set this manually
        next if lc($key) eq 'server';

        # skip HTTP::Response inserted headers
        next if substr( lc($key), 0, 6 ) eq 'client';

        # let apache set these
        next if substr( lc($key), 0, 10 ) eq 'connection';
        next if substr( lc($key), 0, 10 ) eq 'keep-alive';

        # some headers have an unecessary newline appended so chomp the value
        chomp( $headers{$key} );
        if ( $headers{$key} =~ m/\n/ ) {
            $headers{$key} =~ s/\n/ /g;
        }

        $r->log->debug( "Setting header key $key, value " . $headers{$key} )
          if DEBUG;
        $r->headers_out->set( $key => $headers{$key} );
    }

    ###############################
    # possible through a nasty hack, set the server version
    $r->server->add_version_component( $headers{Server} || 'sl');

    ###############################
    # maybe someday but not today, do not cache this response
    $r->no_cache(1);

    return 1;
}

sub twohundred {
    my ( $r, $response ) = @_;

    my $url = $r->pnotes('url');
    $r->log->debug("$$ Request to $url returned 200") if DEBUG;

    # Cache the content_type
    if ( defined $response->content_type && ($response->content_type ne '')) {
        $CACHE->add_known_html( $url => $response->content_type );
    }

    # check to make sure it's HTML first
    $r->log->debug("$$ ===> $url is_html: " . $response->is_html) if DEBUG;
    unless ( $response->is_html ) {
        return _non_html_two_hundred( $r, $response );
    }

    # code above is not a bottleneck
    ####################################

    ################################
    # the request rate limiter
    $TIMER->start('rate_limiter') if TIMING;
    my $user_id = join('|', $r->pnotes('hash_mac'), $r->pnotes('ua'));
    my $is_toofast = $RATE_LIMIT->check_violation($user_id) || 0;
    $r->log->debug("$$ ===> $url check_violation: $is_toofast") if DEBUG;
    $r->log->info( sprintf( "timer $$ %s %s %d %s %f", @{ $TIMER->checkpoint } ) )
      if TIMING;

    ##############################
    # serve an ad if this is not a sub-request of an
    # ad-serving page, and it's not too soon after a previous ad was served
    my $response_content_ref;
    my $ad_served;
    if (
		# not enough content means it's probably not a real page
            ( not $is_toofast )
            and
            ( not $SUBREQUEST_TRACKER->is_subrequest( url => $url ) )
      )
    {

        # put an ad in the response
        $response_content_ref = _generate_response( $r, $response );

        if (!$response_content_ref) {
            # we could not serve an ad on this page for some reason
            $r->log->info("$$ ad not served, _generate_response failed url $url");

        } else {
            # we served an ad, note the ad-serving time for the rate-limiter
            $ad_served = 1;
            $RATE_LIMIT->record_ad_serve($user_id);
        }

    }    # end 'if ('
    else {
        # this is not html or its compressed, etc
        $r->log->debug("$$ ad not served, using existing content") if DEBUG;
    }

    # settings for ad not served
    unless ($ad_served) {
        $response_content_ref = \$response->decoded_content;
    }

    ##############################################
    # grab the links from the page and stash them
    $TIMER->start('collect_subrequests') if TIMING;
    my $subrequests_ref = $SUBREQUEST_TRACKER->collect_subrequests(
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
    if ( defined $subrequests_ref ) {

        # setting in place, replace the links
        my $ok = $SUBREQUEST_TRACKER->replace_subrequests({
            port        => REPLACE_PORT,
            subreq_ref  => $subrequests_ref,
            content_ref => $response_content_ref,
        });
        $r->log->info("$$ could not replace subrequests for url $url") unless $ok;
    }

    # set the status line
    $r->status_line( $response->status_line );
    $r->log->debug( "$$ status line is " . $response->status_line ) if DEBUG;

    # set the response headers
    my $set_ok = _set_response_headers( $r, $response, $response_content_ref);

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
    $r->log->debug("bytes sent: $bytes_sent") if DEBUG;

    # checkpoint
    $r->log->info(
        sprintf( "$bytes_sent bytes sent, timer $$ %s %s %d %s %f",
            @{ $TIMER->checkpoint } )
      )
      if TIMING;

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

    ##############################################################
    # put the ad in the response
    $TIMER->start('random_ad') if TIMING;

    my ( $ad_id, $ad_content_ref, $css_url ) = SL::Model::Ad->random(
        {
            ip   => $r->connection->remote_ip,
            url  => $url,
            mac  => $r->pnotes('router_mac'),
            user => $r->pnotes('hash_mac'),
        }
    );

    # checkpoint random ad
    $r->log->info(
        sprintf( "timer $$ %s %s %d %s %f", @{ $TIMER->checkpoint } ) )
      if TIMING;

    $r->log->debug("Ad content is \n$$ad_content_ref\n") if VERBOSE_DEBUG;
    unless ($ad_content_ref) {
        $r->log->error("$$ Hmm, we didn't get an ad for url $url");
        return;
    }

    # Skip ad insertion if $skips regex match on decoded_content
    # It is a fix for sites like google, yahoo who send encoded UTF-8 et al
    my $decoded_content        = $response->decoded_content;
    my $content_needs_encoding = 1;
	
	unless (length($decoded_content) > MIN_CONTENT_LENGTH) {
	    $r->log->debug("$$ content too small, skipping ad insertion") if DEBUG;
		return;
	}

	unless ( defined $decoded_content ) {

        # hmmm, in some cases decoded_content is null so we use regular content
        # https://www.redhotpenguin.com/bugzilla/show_bug.cgi?id=424
        $decoded_content = $response->content;

        # don't try to re-encode it in this case
        $content_needs_encoding = 0;
    }

    if ( $decoded_content =~ m/$SKIPS/is ) {
        $r->log->debug("$$ Skipping ad insertion from skips regex")
          if DEBUG;
        return;
    }
    else {
        $TIMER->start('container insertion') if TIMING;

        # put the ad in the page
        my $ok =
          SL::Model::Ad::container( $css_url, \$decoded_content,
            $ad_content_ref );

        # checkpoint
        $r->log->info(
            sprintf( "timer $$ %s %s %d %s %f", @{ $TIMER->checkpoint } ) )
          if TIMING;

        unless ($ok) {
            # TODO - mark url to be skipped next time
            $r->log->info(
				"could not insert ad id $ad_id into url $url, css $css_url");
            return;
        }
    }

    # Check to see if the ad is inserted
    unless ( grep( $$ad_content_ref, $decoded_content ) ) {
        require Data::Dumper;
        $r->log->error(
            sprintf( "$$ Ad insertion failed, response: %s",
                Data::Dumper::Dumper($response) )
        );
        $r->log->error(
            "$$ Munged response $decoded_content, ad $$ad_content_ref");
        return;
    }

    # We've made it this far so we're looking good
    $r->log->debug("$$ Ad inserted url $url; referer: $referer;")
      if DEBUG;

    $r->log->debug("$$ Munged response is \n $decoded_content")
      if VERBOSE_DEBUG;

    # Log the ad view later
    $r->pnotes( ad_id => $ad_id );

    # re-encode content if needed
    if ($content_needs_encoding) {
        my $charset = _response_charset($response);

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

# figure out what charset a reponse was made in, code adapted from
# HTTP::Message::decoded_content
sub _response_charset {
    my $response = shift;

    # pull apart Content-Type header and extract charset
    my $charset;
    my @ct =
      HTTP::Headers::Util::split_header_words(
        $response->header("Content-Type") );
    if (@ct) {
        my ( undef, undef, %ct_param ) = @{ $ct[-1] };
        $charset = $ct_param{charset};
    }

    # if the charset wasn't in the http header look for meta-equiv
    unless ($charset) {

        # default charset for HTTP::Message - if it couldn't guess it will
        # have decoded as 8859-1, so we need to match that when
        # re-encoding
        return $charset || "ISO-8859-1";
    }
}

1;
