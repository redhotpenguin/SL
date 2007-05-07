package SL::UserAgent;

use strict;
use warnings;

use LWP::UserAgent ();
use HTTP::Cookies  ();

sub new {
    my $self = shift;

    my $ua = LWP::UserAgent->new(max_redirect => 0);

    # Cookies
    $ua->cookie_jar(HTTP::Cookies->new());

    # Turn off head-parsing.  With this feature on http-equiv headers
    # get promoted into first-class headers, which interferes with the
    # browser's ability to ignore them.
    $ua->parse_head(0);

    return $ua;
}

sub request {
	my ($self, $request) = @_;

	die unless $request->isa('SL::HTTP::Request');

	my $response = $self->SUPER::request($request);

	# Handle browser redirects instead of passing those back to the client
    if ($response->code == 200) {
        if (my $redirect = $self->_browser_redirect($response)) {

			# handle the redirect
			$request->uri($redirect);
            $response = $self->SUPER::request($request);
            unless ($response->code == 200) {
                return $response->code;
            }
        }
    }
	return $response;
}

sub _browser_redirect {
	my ($self, $response) = @_;	
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

	# not a redirect
	return;
}

1;
