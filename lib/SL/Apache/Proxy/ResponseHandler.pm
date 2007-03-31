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
  HTTP_UNAUTHORIZED );
use Apache2::Connection     ();
use Apache2::Log            ();
use Apache2::RequestRec     ();
use Apache2::RequestUtil    ();
use Apache2::RequestIO      ();
use Apache2::ServerRec      ();
use Apache2::ServerUtil        ();
use Apache2::URI            ();
use APR::Table              ();
use HTTP::Headers           ();
use HTTP::Headers::Util     ();
use HTTP::Message           ();
use HTTP::Request           ();
use HTTP::Response          ();
use SL::UserAgent           ();
use SL::Model::Ad           ();
use SL::Model::Subrequest   ();
use SL::Model::RateLimit    ();
use Data::Dumper            qw( Dumper );
use Encode                  ();

our %response_map = (
            200 => 'twohundred',
            404 => 'fourohfour',
            500 => 'bsod',
            400 => 'badrequest',
            401 => 'fourohone',
            302 => 'redirect',
            301 => 'redirect',
            304 => 'threeohfour',
            307 => 'redirect',
           );

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

my $try_container = 1;   # signals we will attempt to use the container approach

our $skips;

BEGIN {
    require Regexp::Assemble;

    $skips = Regexp::Assemble->new;

    # Skip pages with stylesheets and skip embedded google ads
    my @skips = qw( framset adwords.google.com );
    push @skips, 'Ads by Goooooogle';
    $skips->add(@skips);
    print STDERR "Regex for content insertion skips ", $skips->re, "\n";

}


=head1 METHODS

=over 4

=item C<handler($r)>

=cut

sub _add_headers {
    my ($r, $proxy_req) = @_;

        
    $r->headers_in->do( sub {
            my $k = shift;
            my $v = shift;
            if ($k eq 'If-Modified-Since' or 
                $k eq 'If-None-Match' or 
                $k eq 'Accept-Encoding') {
                $r->log->debug("Skipping add of header $k");
                return 1;
            }
            # FIXME - warning tht $proxy_req will not stay shared
            #        $r->log->debug("Header key $k, val $v to proxy request $proxy_req");
            $proxy_req->header($k => $v);
            return 1;
        },
        #    () # use an empty list for the filters - see APR::Table::do
    );
}

sub handler {
    my $r = shift;

    #$DB::single = 1;
    my $url          = $r->pnotes('url');
    my $ua           = $r->pnotes('ua');
    my $referer      = $r->pnotes('referer');
    my $content_type = $r->pnotes('content_type');

    $r->log->debug("$$ PRH handler url $url, user-agent $ua, referer $referer");
    $r->log->debug("$$ Request is \n" . $r->the_request);
    $r->log->debug("$$ Request as string \n" . $r->as_string);
    $r->log->debug("$$ Unparsed uri is \n" . $r->unparsed_uri);

    ## Build the remote request
    my $response = _make_request($r);
    #$r->log->debug("Response is " . Dumper($response));
    
    # Dispatch the response
    my $sub = $response_map{$response->code};
    unless ($sub) {
        $r->log->error(sprintf("No handler for res code %d, url %s, ua %s",
            $response->code, $url, $ua));
		$sub = $response_map{'404'};
	}
    no strict 'refs';
    $r->log->info("Response code " . $response->code);
    return &$sub($r, $response);
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
    my $res         = shift;

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

    # this print causes the response to go out as a 200, not a 401.
    # No idea why...
    # $r->print($res->content);

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

    my $url = $response->request->uri;
    $r->log->info("$$ Request to $url returned 200");
    
    #VERBOSE
    #$r->log->debug("$$ Response from server:  \n", $response->content);
    
    # Cache the content_type
    my $response_content;
    SL::Cache::stash($url => $response->content_type);

    # check to make sure it's HTML first
    my $is_html = not SL::Util::not_html($response->content_type);
    $r->log->debug("===> $url is_html: $is_html");

    # check the rate-limiter, if it's HTML
    my $rate_limit = SL::Model::RateLimit->new(r => $r);
    my $is_toofast;
    if ($is_html) {
        $is_toofast = $rate_limit->check_violation();
        $r->log->debug("===> $url check_violation: $is_toofast");
    }
    
    # check for sub-reqs if it passed the other tests
    my $subrequest_tracker = SL::Model::Subrequest->new(); 
    my $is_subreq;
    if ($is_html and not $is_toofast) {
        $is_subreq = $subrequest_tracker->is_subrequest(url => $url);
        $r->log->debug("===> $url is_subreq: $is_subreq");
    }

    # serve an ad if this is HTML and it's not a sub-request of an
    # ad-serving page, and it's not too soon after a previous ad was served
    if ($is_html and not $is_toofast and not $is_subreq) {

        # note the ad-serving time for the rate-limitter
        $rate_limit->record_ad_serve();

        # first grab the links from the page and stash them
        $subrequest_tracker->collect_subrequests(
                                           content_ref => \$response->content,
                                           base_url    => $url);

        # put the ad in the response
        $response_content = _generate_response($r, $response);
        
    }
    else {

        # this is not html
        $response_content = $response->content;
    }

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
        #$r->log->debug("$$ added set-cookie header: $cookie");
    }
    $response->headers->remove_header('Set-Cookie');
    
    # Create a hash with the HTTP::Response HTTP::Headers attributes
    $response->scan(sub { $headers{$_[0]} = $_[1]; });
    $r->log->debug("Response headers: " . Dumper(\%headers));

    ## Set the response content type from the request, preserving charset
    my $content_type = $response->header('content-type');
    
    my $ua = $r->pnotes('ua');
    
    # Cleanse the content-type.  I first noticed this with Opera 9.0 on the 
    # Mac when doing a google toolbar search the first time I used Opera 9
    # I saw this happen on IE first though
    # IE is very picky about it's content type so we use a hack here - FIXME
    if (! $ua) { $r->log->error("UA $ua for url $url") };    
    if ( ($ua =~ m{(?:MSIE|opera)}i) && ($content_type =~ m{^text\/html}) ) {
    $r->content_type('text/html');
        $r->log->debug("$$ MSIE content type set to text/html");
    } elsif (! $content_type) {
    $r->content_type('text/html');
        $r->log->error("$$ Undefined content type, setting to text/html");
    } else {
        $r->content_type($content_type);
        $r->log->debug("$$ content type set to $content_type");
    }
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

    $r->headers_out->add('X-SilverLining' => 1);
    $r->log->debug("$$ x-silverlining header set");
    delete $headers{'Client-Peer'};
    delete $headers{'Content-Encoding'};
    
    foreach my $key (keys %headers) {
        next if $key =~ m/^Client/; # skip HTTP::Response inserted headers
        
        # some headers have an unecessary newline appended so chomp the value
        chomp($headers{$key});
        if ( $headers{$key} =~ m/\n/ ) {
            $headers{$key} =~ s/\n/ /g;
        }
        #$r->log->debug(
        #        "Setting key $key, value "
        #      . $headers{$key}
        #      . " to headers"
        #);

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
    $r->print($response_content);
    return Apache2::Const::OK;
}

sub _build_post {
    my $r = shift;

    my ($buf, $cnt);
    my $len = '4096';
    while ($r->read($buf, $len)) {
        $cnt .= $buf;
    }
    $r->log->debug("Post content for proxy req: $cnt");
    return $cnt;
}

sub _make_request {
    my $r = shift;

    ## Make a user agent
    my $ua = SL::UserAgent->new($r);

    ## Grab the url from pnotes
    my $url = $r->pnotes('url');

    ## Create a request object
    my $proxy_req = HTTP::Request->new( $r->method, $r->construct_url($r->unparsed_uri));
    $r->log->debug("$$ Adding headers");
    _add_headers($r, $proxy_req);
    
    ## Do this schiznit for a post request
    if ($r->method eq 'POST') {

        $r->log->info("$$ Building content for POST, url $url");

        my $content = _build_post($r);
        $proxy_req->content($content);
        
    }

    $r->log->debug("$$ Proxy req to remote server: \n" . $proxy_req->as_string);

    # Make the request to the remote server
    my $response = $ua->request($proxy_req);

    # Handle browser redirects instead of passing those back to the client
    if ($response->code == 200) {
        if (my $redirect = _browser_redirect($response)) {
            $r->log->debug("$$ Executing browser redirect to $redirect");
            $proxy_req->uri($redirect);
            $response = $ua->request($proxy_req);
            unless ($response->code == 200) {
                return $response->code;
            }
        }
    }
    return $response;
}

sub _browser_redirect {
    my $response = shift;

    # Examine the response content and return the browser redirect url if found
    if (
        my ($redirect) =
        $response->content =~ m/
        (s-xism:<meta\s+http-equiv\s*?=\s*?"Refresh"\s*?content\s*?=\s*?"?0"?\;
        ss*?url\s*?=\s*?(http:\/\/\w+\.[^\"|^\>|\s]+))/xmsi
       )
    {
        return $redirect;
    }
}

=item C<_generate_response( $r, $response )>

Puts the ad in the response

=cut

sub _generate_response {
    my ($r, $response) = @_;

    # yes this is ugly but it helps for testing
    #return $response->decoded_content;
    
    $r->log->info( "$$ grabbing ad for request uri " . $r->uri );
    my ($ad_id, $ad_content_ref, $css_url) = 
        SL::Model::Ad->random($r->connection->remote_ip);
    
    # VERBOSE
    $r->log->debug( "Ad content is \n$$ad_content_ref\n");
    unless ($ad_content_ref) {
        $r->log->error("$$ Hmm, we didn't get an ad");
        return $response->content;
    }

    my $url     = $r->pnotes('url');
    my $ua      = $r->pnotes('ua');
    my $referer = $r->pnotes('referer');

    # Skip ad insertion if $skips regex match on decoded_content
    # It is a fix for sites like google, yahoo who send encoded UTF-8 et al
    my $munged_resp;
    my $decoded_content = $response->decoded_content;
    my $content_needs_encoding = 1;

    unless (defined $decoded_content) {
        # hmmm, in some cases decoded_content is null so we use regular content
        # https://www.redhotpenguin.com/bugzilla/show_bug.cgi?id=424
        $decoded_content = $response->content;

        # don't try to re-encode it in this case
        $content_needs_encoding = 0;
    }
       
    if ($decoded_content =~ m/$skips/ims) {
        $r->log->info("Skipping ad insertion from skips regex");
        return $response->content;
    }
    else {
        $r->log->debug("Using container method for ad insertion");
        $munged_resp =
              SL::Model::Ad::container($css_url,
                                       $decoded_content, $ad_content_ref);
    }

    # Check to see if the ad is inserted
    unless (grep($$ad_content_ref, $munged_resp)) {
        $r->log->error("$$ Ad insertion failed! try_container is ",
                       $try_container, "; response is ",
                       Dumper($response));
        $r->log->error("$$ Munged response $munged_resp, ad $$ad_content_ref");
        return $response->content;
    }

    # We've made it this far so we're looking good
    $r->log->info("$$ Ad inserted for url $url; try_container: ",
                  $try_container, "; referer : $referer; ua : $ua;");
    #$r->log->debug("Munged response is \n $$munged_resp");
        
    # Log the ad view later
    $r->pnotes( log_data => [ $r->connection->remote_ip, $ad_id ] );

    # re-encode content if needed
    if ($content_needs_encoding) {
        my $charset = _response_charset($response);

        # don't need to worry about errors - this content came from
        # Encode::decode via HTTP::Message::decoded_content, so as
        # long as we don't start putting in non-ASCII ad content we
        # should have no problems round-tripping.  If an error does
        # occur the character will be replaced with a "subchar"
        # specific to the encoding.
        $munged_resp = Encode::encode($charset, $munged_resp);
    }

    return $munged_resp;
}

# figure out what charset a reponse was made in, code adapted from
# HTTP::Message::decoded_content
sub _response_charset {
    my $response = shift;

    # pull apart Content-Type header and extract charset
    my $charset;
    my @ct =
      HTTP::Headers::Util::split_header_words(
                                           $response->header("Content-Type"));
    if (@ct) {
        my (undef, undef, %ct_param) = @{$ct[-1]};
        $charset = $ct_param{charset}
    }

    # default charset for HTTP::Message - if it couldn't guess it will
    # have decoded as 8859-1, so we need to match that when
    # re-encoding
    return $charset || "ISO-8859-1"; 
}

1;
