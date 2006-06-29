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

use Apache2::Const -compile => qw( OK SERVER_ERROR NOT_FOUND DECLINED
  REDIRECT LOG_DEBUG LOG_ERR LOG_INFO CONN_KEEPALIVE);
use Apache2::Connection     ();
use Apache2::ConnectionUtil ();
use Apache2::Cookie         ();
use Apache2::Log            ();
use Apache2::Request        ();
use Apache2::RequestRec     ();
use Apache2::RequestIO      ();
use Apache2::ServerRec      ();
use Apache2::URI            ();
use APR::Table              ();
use HTTP::Headers           ();
use HTTP::Message           ();
use HTTP::Request           ();
use HTTP::Response          ();
use SL::UserAgent           ();
use SL::Model::Ad           ();

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
       </div>
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
    my @skips = qw( adwords.google.com );
    push @skips, 'Ads by Goooooogle';
    $skips->add(@skips);
    print STDERR "Regex for content insertion skips ", $skips->re, "\n";

}

use Apache2::Const;
use Apache2::RequestRec;
use Apache2::RequestUtil;
use Apache2::ServerRec;
use Apache2::ServerUtil;

=head1 METHODS

=over 4

=item C<handler($r)>

=cut

sub _add_headers {
    my ( $r, $proxy_req, $cookies, $ua ) = @_;
	
	($r->server->loglevel == Apache2::Const::LOG_DEBUG) &&
		require Data::Dumper &&
		$r->log->debug("Cookies are " . Dumper($cookies));
	
	use HTTP::Cookies;
	my $jar = $ua->cookie_jar();
	
	#{
	#    no warnings;
	#    $cookies->do(
	#        sub {
	#            my ($key, $value) = @_;
	#
	#            $r->log->debug("$$ url ", $r->pnotes('url'),
	#                           ", cookie key $key, value $value");
	#
	#            $proxy_req->header($key => $value);
	#        }
	#    );
	#}
	#return $proxy_req;
	
	foreach my $cookie ( keys %{$cookies} ) {
		my $path = $cookies->{$cookie}->path || '/';
		my $domain = $cookies->{$cookie}->domain || $proxy_req->uri->host;
		my $name = $cookies->{$cookie}->name;
		my $port = $cookies->{$cookie}->port || '80';
		$r->log->debug(
			",Cookie version: " . $cookies->{$cookie}->version . 
			",Cookie name: " . $name . 
			",Cookie value: " . $cookies->{$cookie}->value . 
			",Cookie path: " . $path . 
			",Cookie domain: " . $domain . 
			",Cookie port: " . $port . 
			",Cookie secure: " . $cookies->{$cookie}->secure); 
		$ua->cookie_jar->set_cookie( $cookies->{$cookie}->version,
						  $name,
						  $cookies->{$cookie}->value,
						  $path,
						  $domain,
						  $port,
						  1,
						  $cookies->{$cookie}->secure,
						  1149393645,
						  0,) or die;
		$r->log->debug("Cookie isa " . ref $cookies->{$cookie});
	} 
	if ($r->server->loglevel == Apache2::Const::LOG_DEBUG) {
		require Data::Dumper;
		$r->log->debug("******\n\n** Proxy request is " . 
			Data::Dumper::Dumper($proxy_req));
		$r->log->debug("******\n\n** UA is " . Data::Dumper::Dumper($ua));
	}
	
	return $proxy_req;
}

sub handler {
    my $r = shift;

    $DB::single = 1;
    my $url          = $r->pnotes('url');
    my $ua           = $r->pnotes('ua');
    my $referer      = $r->pnotes('referer');
    my $content_type = $r->pnotes('content_type');

    $r->log->info("$$ PRH handler url $url, user-agent $ua, referer $referer");

    ## Build the remote request
    my $response = _make_request($r);
    my $response_content;

    # Handle the response on a case basis depending on response code
    my $rc;
	if ($response->code == 500) {
        ($r->server->loglevel == Apache2::Const::LOG_ERR)
          && require Data::Dumper
          && $r->log->error("$$ Request returned 500, response ",
                            Data::Dumper::Dumper($response));
        return Apache2::Const::SERVER_ERROR;
    }
    elsif ($response->code == 404) {
        ($r->server->loglevel == Apache2::Const::LOG_ERR)
          && require Data::Dumper
          && $r->log->error("$$ Request returned 404, response ",
                            Data::Dumper::Dumper($response));
        return Apache2::Const::NOT_FOUND;
    }
    elsif ($response->code == 302 or $response->code == 301) {
        $r->log->info("$$ Request to $url returned 302 or 301");
        $r->log->debug("$$ Redirect returned, response", $response->code);
        ($r->server->loglevel == Apache2::Const::LOG_DEBUG)
          && require Data::Dumper
		  && $r->log->debug("$$ headers: " . Data::Dumper::Dumper(
				  $response->headers));

        ## Handle the redirect for the client
		$r->log->debug("$$ Request: " . $r->as_string);
        $rc = Apache2::Const::REDIRECT;
    }
    elsif ($response->code == 200) {
        $r->log->info("$$ Request to $url returned 200");
        ($r->server->loglevel == Apache2::Const::LOG_DEBUG)
          && require Data::Dumper
          && $r->log->debug("$$ Response from server:  ",
                            Data::Dumper::Dumper($response));

        # Cache the content_type
        SL::Cache::stash($url => $response->content_type);
        if (not SL::Util::not_html($response->content_type)) {

            # first grab the links from the page and stash them
            my $links = SL::Util->extract_links($response->content, $r);
            $r->log->debug("$$ Links extracted: " . join(', ', @{$links}));
            my $c = $r->connection;
            $c->pnotes('rlinks' => $links);
            $r->server->loglevel == Apache2::Const::LOG_DEBUG
              && require Data::Dumper
              && $r->log->debug(  "$$ connection id _"
                                . $c->id
                                . "_ pnotes: "
                                . Data::Dumper::Dumper($c->pnotes('rlinks'))
                                . " keepalive? "
                                . $c->keepalive);

            # put the ad in the response
            $response_content = _generate_response($r, $response);
        }
        else {

            # this is not html
            $response_content = $response->content;
        }
		$rc = Apache2::Const::OK;
    }
    else {
        ($r->server->loglevel == Apache2::Const::LOG_ERR)
          && require Data::Dumper
          && $r->log->error("$$ Request to $url failed: ",
                            Data::Dumper::Dumper($response));
        return Apache2::Const::SERVER_ERROR;
    }
    # set the status line
    $r->status_line( $response->code() . ' ' . $response->message() );

    # IE doesn't like content types passed as an array reference
    # Certain sites return content type in the form
    # [ 'text/html', 'text/html ISO xxxxxx' ]
#    if ($ua =~ m/Internet Explorer/) {

        #     # Set the content type to text/html
#        $r->content_type('text/html');

        #     # Explicit elsif to constrain the truth table
#    }
#    elsif ($ua !~ m/Internet Explorer/) {
#        $r->content_type($type);
#    }

	# This loops over the response headers and adds them to headers_out.
	# Override any headers with our own here
	#$r->assbackwards(1);
	$DB::single = 1;
	my %headers;
	$r->headers_out->clear();
	
	$response->scan( sub { $headers{$_[0]} = $_[1]; } );
	
	require Data::Dumper &&
		$r->log->debug("Response headers: " . Data::Dumper::Dumper(\%headers));
	
	## Set the response content type
	$content_type = $response->header('content_type');
    $r->content_type($content_type);
	delete $headers{'Content-Type'};

	## Content encoding
    $r->content_encoding($response->header('content-encoding'));
	delete $headers{'Content-Encoding'};
	
	## Content languages
	$r->content_languages($response->header('content_language'));
	delete $headers{'Content-Language'};
	
	$r->headers_out->add('X-SilverLining' => 1);

	delete $headers{'Client-Transfer-Encoding'};
	delete $headers{'Client-Response-Num'};

	foreach my $key ( keys %headers ) {
		$r->log->debug("Adding key $key, value " . $headers{$key} . " to headers
");
		$r->headers_out->set($key => $headers{$key});
	}

	$r->connection->keepalive(1);
	$r->no_cache(1);
	# rflush() flushes the headers to the client
	# thanks to gozer's mod_perl for speed presentation
    $r->rflush();

	# Print the response content
    $r->print($response_content);
    return $rc;
}

sub _make_request {
    my $r = shift;

    ## Rebuild the query string for the remote request
    my $req = Apache2::Request->new($r);

    ## Grab the cookies
    my %cookies = Apache2::Cookie->fetch($r);

    ## Make a user agent
    my $ua = SL::UserAgent->new($r);

    ## Grab the url from pnotes
    my $url = $r->pnotes('url');

    ## Create a request object
    my $proxy_req = HTTP::Request->new($r->method(), $url);
    if (keys %cookies) {
		$r->log->debug("$$ Adding headers");
        $proxy_req = _add_headers( $r, $proxy_req, \%cookies, $ua );
    }

    ## Do this schiznit for a post request
    if ($r->method eq 'POST') {
        $r->log->info("$$ Building content for POST, url $url");
        my $body = $req->param;
        my $content;

        foreach my $key (keys %$body) {
            my $value = $body->get($key);
            $r->log->debug("$$ POST body key is $key, value is $value");
            if ($content) {
                $content .= "&";
            }
            $content .= "$key=$value";
        }
        $proxy_req->content($content);
    }

    ($r->server->loglevel == Apache2::Const::LOG_DEBUG)
      && require Data::Dumper
      && $r->log->debug("$$ Proxy request to remote server: ",
                        Data::Dumper::Dumper($proxy_req));

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

    my $ad;
    my $ad_ua   = SL::UserAgent->new($r);
    my $ad_url  = $r->dir_config('ad_url');
    my $ad_req  = HTTP::Request->new('GET', $ad_url);
    my $ad_resp = $ad_ua->request($ad_req);

    my $url     = $r->pnotes('url');
    my $ua      = $r->pnotes('ua');
    my $referer = $r->pnotes('referer');

    if ($ad_resp->code != 200) {
        $r->log->error("$$ ALERT!  Could not retrieve ad from adserver");
        ($r->server->loglevel == Apache2::Const::LOG_ERR)
          && require Data::Dumper
          && $r->log->error(
            "$$ ALERT!  
			Response ", Data::Dumper::Dumper($ad_resp));
        return $response->content;
    }
    else {
        $ad = $ad_resp->content;
    }

    # Skip ad insertion if $skips regex match on decoded_content
    # The decoded_content method is used for a reason so don't refactor it :)
    # It's a fix for sites like google, yahoo who send encoded UTF-8 et al
    my $munged_resp;
    my $decoded_content = $response->decoded_content;
    if ($decoded_content =~ m/$skips/ixms) {
        $r->log->info("Skipping ad insertaion from skips regex");
        return $response->content;
    }
    elsif ($r->dir_config("SLMethod") eq 'Stacked') {
        $r->log->debug("Using stacked method for ad insertion");
        $munged_resp = SL::Model::Ad::stacked($decoded_content, $ad);
    }
    elsif ($r->dir_config("SLMethod") eq 'Container') {
        if ($r->dir_config("SLMethod") eq 'Container') {
            $r->log->debug("Using container method for ad insertion");
            $munged_resp =
              SL::Model::Ad::container($r->dir_config('SLCssUri'),
                                       $decoded_content, $ad);
        }
        else {
            return $response->content;
        }
    }

    # Check to see if the ad is inserted
    unless (grep($ad, $munged_resp)) {
        $r->server->loglevel == Apache2::Const::LOG_ERR
          && require Data::Dumper
          && $r->log->error(
                            "$$ Ad insertion failed! try_container is ",
                            $try_container,
                            "; response is ",
                            Data::Dumper::Dumper($response)
                           );
        $r->log->error("$$ Munged response $munged_resp, ad $ad");
        return $response->content;
    }

    # We've made it this far so we're looking good
    $r->log->info("$$ Ad $ad inserted for url $url; try_container: ",
                  $try_container, "; referer : $referer; ua : $ua;");
    $r->log->debug("Munged response is \n $munged_resp");
    return $munged_resp;
}

