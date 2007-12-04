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
  HTTP_NO_CONTENT HTTP_PARTIAL_CONTENT);
use Apache2::Connection      ();
use Apache2::Log             ();
use Apache2::RequestRec      ();
use Apache2::RequestUtil     ();
use Apache2::RequestIO       ();
use Apache2::Response        ();
use Apache2::ServerRec       ();
use Apache2::ServerUtil      ();
use Apache2::URI             ();
use APR::Table               ();
use SL::HTTP::Request        ();
use SL::UserAgent            ();
use SL::Model::Ad            ();
use SL::Cache                ();
use SL::Cache::Subrequest    ();
use SL::Cache::RateLimit     ();
use SL::Model::Proxy::Router ();
use Encode                   ();
use RHP::Timer               ();
use Regexp::Assemble         ();
use Compress::Zlib           ();
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
    307 => 'redirect',
    500 => 'bsod',
    400 => 'badrequest',
    401 => 'fourohone',
    403 => 'fourohthree',
    404 => 'fourohfour',
);

## Make a user agent
my $SL_UA = SL::UserAgent->new;

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
      MM_executeFlashDetection
      swfobject.js );
    push @skips, 'Ads by Goo';
    $SKIPS = Regexp::Assemble->new->add(@skips)->re;
    print STDERR "Regex for content insertion skips ", $SKIPS, "\n" if DEBUG;
}

sub handler {
    my $r = shift;

    # Build the request
    my %headers;
    $r->headers_in->do(
        sub {
            my $k = shift;
            my $v = shift;
            if ( $k !~ m/^X-SL/ ) {
                $headers{$k} = $v;
            }
            return 1;    # don't remove me
        }
    );
    $headers{'Referer'} = $r->pnotes('referer')
      if ( $r->pnotes('referer') ne 'no_referer' );

    # this is a whacked hack
    $headers{'Connection'} = 'keep-alive';

    # work around clients which don't support compression
    if ( !exists $headers{'Accept-Encoding'} ) {
        $r->log->debug( "$$ client DOES NOT support compression "
              . Data::Dumper::Dumper( \%headers ) )
          if DEBUG;
        $headers{'Accept-Encoding'} = 'gzip, deflate';
    }
    else {
        $r->log->debug(
            "$$ client supports compression " . $headers{'Accept-Encoding'} )
          if DEBUG;
        $r->pnotes(
            'client_supports_compression' => $headers{'Accept-Encoding'} );
    }

    $r->log->debug(
        "$$ proxy request headers " . Data::Dumper::Dumper( \%headers ) )
      if DEBUG;

    my $proxy_request = SL::HTTP::Request->new(
        {
            method  => $r->method,
            url     => $r->pnotes('url'),
            headers => \%headers,
        }
    );

    # the code above is not a bottleneck
    # start the clock
    $TIMER->start('make_remote_request') if TIMING;

    $r->log->debug(
        sprintf( "$$ Remote proxy request: \n%s", $proxy_request->as_string ) )
      if DEBUG;

    # Make the request to the remote server
    my $response = $SL_UA->request($proxy_request);

    $r->log->debug(
        "$$ Response headers from proxy request",
        Data::Dumper::Dumper( $response->headers )
      )
      if DEBUG;

    # checkpoint
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
    return &$sub( $r, $response );
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
    $r->server->add_version_component( $headers{Server} );
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
    );

    # set the status line
    #$r->status($res->code);
    $r->log->debug( "status line is " . $res->status_line );

    # translate the headers from the remote response to the proxy response
    my $translated = _translate_headers( $r, $res );

    # rflush() flushes the headers to the client
    # thanks to gozer's mod_perl for speed presentation
    #$r->rflush();

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

    $r->log->debug(
        sprintf(
            "$$ status line %s, response: %s",
            $res->status_line, Data::Dumper::Dumper($res)
        )
    );

    # set the status line
    #$r->status($res->code);
    $r->log->debug( "status line is " . $res->status_line ) if DEBUG;

    # translate the headers from the remote response to the proxy response
    my $translated = _translate_headers( $r, $res );

    # rflush() flushes the headers to the client
    # thanks to gozer's mod_perl for speed presentation
    $r->rflush();

    $r->log->error(
        sprintf(
            "header translation error \$r: %s, \$res %s",
            $r->as_string, Data::Dumper::Dumper($res)
        )
      )
      unless $translated;

    $r->log->debug( "$$ Request: \n" . $r->as_string ) if VERBOSE_DEBUG;

    # do not change this line
    return Apache2::Const::HTTP_SEE_OTHER;
}

sub twohundred {
    my ( $r, $response ) = @_;

    my $url = $response->request->uri;
    $r->log->debug("$$ Request to $url returned 200") if DEBUG;

    # Cache the content_type
    my $response_content_ref;
    if ( defined $response->content_type ) {
        $CACHE->add_known_html( $url => $response->content_type );
    }

    # check to make sure it's HTML first
    my $is_html = not SL::Util::not_html( $response->content_type );
    $r->log->debug("$$ ===> $url is_html: $is_html") if DEBUG;

    # code aboe is not a bottleneck
    $TIMER->start('rate_limiter') if TIMING;

    my $is_toofast;
    my $user_id;
    if ($is_html) {
        if ( $r->pnotes('sl_header') ) {
            $user_id = $r->pnotes('sl_header');
        }
        else {
            $user_id =
              join ( '|', $r->connection->remote_ip, $r->pnotes('ua') );
        }

        $is_toofast = $RATE_LIMIT->check_violation($user_id) || 0;
        $r->log->debug("$$ ===> $url check_violation: $is_toofast")
          if DEBUG;
    }

    # serve an ad if this is HTML and it's not a sub-request of an
    # ad-serving page, and it's not too soon after a previous ad was served
    my $subrequests_ref;
    if (
        (
                $is_html
            and ( not $is_toofast )
            and (
                not $SUBREQUEST_TRACKER->is_subrequest(
                    url => $r->pnotes('url') ) )
        )
      )
    {

        # note the ad-serving time for the rate-limiter
        $RATE_LIMIT->record_ad_serve($user_id);

        $response_content_ref = _generate_response( $r, $response );

        if (TIMING) {
            $r->log->info(
                sprintf( "timer $$ %s %s %d %s %f", @{ $TIMER->checkpoint } ) );
            $TIMER->start('collect_subrequests');
        }

        # first grab the links from the page and stash them
        $TIMER->start('collect_subrequests') if TIMING;

        $subrequests_ref = $SUBREQUEST_TRACKER->collect_subrequests(
            content_ref => $response_content_ref,
            base_url    => $url
        );

        # checkpoint
        $r->log->info(
            sprintf( "timer $$ %s %s %d %s %f", @{ $TIMER->checkpoint } ) )
          if TIMING;

    }    # end 'if ( $is_html and...'
    else {

        # this is not html
        $response_content_ref = \$response->content;
    }

    ###########
    # we replace the links even on pages that we don't serve ads on to
    # speed things up
    # replace the links if this router/location has a replace_port setting
    my $rep_ref = eval {
        SL::Model::Proxy::Router->replace_port( $r->connection->remote_ip );
    };
    if ($@) {
        $r->log->error( sprintf( "error getting replace_port for ip %s", $@ ) );
    }

    if (   ( defined $rep_ref )
        && ( !$@ )
        && ( defined $subrequests_ref ) )
    {

        # setting in place, replace the links
        my $ok = $SUBREQUEST_TRACKER->replace_subrequests(
            {
                port        => $rep_ref->[1],           # r_id, port
                subreq_ref  => $subrequests_ref,
                content_ref => $response_content_ref,
            }
        );
        $r->log->error("$$ could not replace subrequests") unless $ok;
    }

    # set the status line
    $r->status_line( $response->status_line );
    $r->log->debug( "$$ status line is " . $response->status_line )
      if DEBUG;

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
    $r->content_type( $headers{'Content-Type'} );
    delete $headers{'Content-Type'};

    ## Content languages
    if ( defined $headers{'content-language'} ) {
        $r->content_languages( [ $response->header('content-language') ] );
        $r->log->debug( "$$ content languages set to "
              . $response->header('content_language') )
          if DEBUG;
        delete $headers{'Content-Language'};
    }

    if (SL_XHEADER) {
        $r->headers_out->add( 'X-SilverLining' => 1 );
        $r->log->debug("$$ x-silverlining header set") if DEBUG;
    }

    # set the content-length if deflate is not turned
    # on AND we are not compressing html content
    $r->log->debug(
        sprintf(
            "is html: %s, compression supported %s",
            $is_html,
            $r->pnotes('client_supports_compression'),
            $headers{'Content-Encoding'}
        )
      )
      if DEBUG;
    if ( $is_html && $r->pnotes('client_supports_compression') ) {

        if ( !exists $headers{'Content-Encoding'} ) {
            $r->log->debug("$$ no existing encoding headers so use gzip")
              if DEBUG;
        }
        else {
            $r->log->debug(
                "$$ existing content encoding " . $headers{'Content-Encoding'} )
              if DEBUG;
            $r->content_encoding( $headers{'Content-Encoding'} );
        }

        if ( $headers{'Content-Length'} ) {
            $r->log->error(
                "$$ content-length header on gzipped response for $url");
        }
        delete $headers{'Content-Encoding'};
        delete $headers{'Content-Length'};
    }
    else {
        $r->set_content_length( length($$response_content_ref) );
    }

    # this is for any additional headers
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

    # possible through a nasty hack
    $r->log->debug( "$$ server header is " . $headers{Server} ) if DEBUG;
    $r->server->add_version_component( $headers{Server} );

    # FIXME
    # this is not setting the Keep-Alive header at all for some reason
    $r->connection->keepalive(Apache2::Const::CONN_KEEPALIVE);

    # maybe someday but not today
    $r->no_cache(1);

    $r->log->debug( "$$ Reponse headers to client " . $r->as_string )
      if DEBUG;

    $r->log->debug( "$$ Response content: " . $$response_content_ref )
      if VERBOSE_DEBUG;

    my $gzip_content;
    if ( $is_html && $r->pnotes('client_supports_compression') ) {
        $gzip_content = Compress::Zlib::memGzip($response_content_ref);
        $r->set_content_length( length($gzip_content) );
    }

    # rflush() flushes the headers to the client
    # thanks to gozer's mod_perl for speed presentation
    $r->rflush();

    # Print the response content
    $TIMER->start('print_response') if TIMING;

    my $bytes_sent;
    if ( $is_html && $r->pnotes('client_supports_compression') ) {

        # we are compressing html so compress it
        $r->log->debug(
            sprintf( "content encoding is _%s_", $r->content_encoding ) )
          if DEBUG;
        if ( $r->content_encoding eq 'gzip' ) {

            $bytes_sent = $r->print($gzip_content);
        }
        elsif ( $r->content_encoding eq 'deflate' ) {

            $bytes_sent = $r->print($gzip_content);
        }
        else {
            $r->log->error( "$$ unsupported encoding " . $r->content_encoding );
            $bytes_sent = $r->print($$response_content_ref);
        }
    }
    else {
        $bytes_sent = $r->print($$response_content_ref);
        $r->log->debug("bytes sent, no compression: $bytes_sent") if DEBUG;

    }

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

    # checkpoint
    $r->log->info(
        sprintf( "timer $$ %s %s %d %s %f", @{ $TIMER->checkpoint } ) )
      if TIMING;

    $r->log->debug("Ad content is \n$$ad_content_ref\n") if VERBOSE_DEBUG;
    unless ($ad_content_ref) {
        $r->log->error("$$ Hmm, we didn't get an ad for url $url");
        return \$response->content;
    }

    # Skip ad insertion if $skips regex match on decoded_content
    # It is a fix for sites like google, yahoo who send encoded UTF-8 et al
    my $decoded_content        = $response->decoded_content;
    my $content_needs_encoding = 1;

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
        return \$response->content;
    }
    else {
        $TIMER->start('container insertion') if TIMING;

        # put the ad in the page
        my $ok =
          SL::Model::Ad::container( $css_url, \$decoded_content,
            $ad_content_ref );

        unless ($ok) {
            $r->log->error(
                "could not insert ad into page url $url, css $css_url, ad "
                  . Data::Dumper::Dumper($ad_content_ref) );
            return \$response->content;
        }

        # checkpoint
        $r->log->info(
            sprintf( "timer $$ %s %s %d %s %f", @{ $TIMER->checkpoint } ) )
          if TIMING;
    }

    # Check to see if the ad is inserted
    unless ( grep( $$ad_content_ref, $decoded_content ) ) {
        $r->log->error(
            sprintf( "$$ Ad insertion failed, response: %s",
                Data::Dumper::Dumper($response) )
        );
        $r->log->error(
            "$$ Munged response $decoded_content, ad $$ad_content_ref");
        return \$response->content;
    }

    # We've made it this far so we're looking good
    $r->log->debug("$$ Ad inserted url $url; referer: $referer; ua: $ua;")
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
