package SL::HTTP::Client;

use strict;
use warnings;

our $VERSION = 0.03;

=head1 NAME

SL::HTTP::Client - HTTP client for making requests to arbitrary host and port

=head1 SYNOPSIS

  use SL::HTTP::Client;

  # make a request through an SL proxy at 192.168.1.50:8069
  my $response = SL::HTTP::Client->get(
    url => 'http://www.tronguy.net/pictures.shtml',
    host => '192.168.1.50',
    port => 8069);

  # reponse is an HTTP::Response object, treat as usual
  if ($response->is_success) {
     my $content = $response->content;
     # ...
  }

=head1 DESCRIPTION

This module provides a way to make HTTP GET requests to arbitrary
host/port combinations.  This is useful for testing SL proxy servers
and may have other applications.

=head1 INTERFACE

=head2 get

  $response = SL::HTTP::Client->get(
    url => 'http://www.tronguy.net/pictures.shtml',
    host => '192.168.1.50',
    port => 8069,
    headers => { 'User-Agent' => 'Opera' });

The get() method requires three named parameters:

  url - the URL for the request, including query params if any

  host - the host to send the request to, does not need to match URL

  port - the port to send the request to

An optional 'headers' parameter is supported, which may contain a hash
(or array-ref) of headers to add to the response.  By default the
'User-Agent' header is set to:

  Mozilla/5.0 (X11; U; Linux i686; en-US; rv:1.8.0.2) Gecko/20060308 Firefox/1.5.0.2

The return value is a HTTP::Response object.  This method will die()
if it encounters network communication problems.

=cut

use URI;
use Net::HTTP;
use HTTP::Response;
use HTTP::Headers;
use Carp qw(croak);

use SL::Config;
our $Config;

BEGIN {
    $Config = SL::Config->new;
}

use constant DEBUG => $ENV{SL_DEBUG} || 0;
use constant MAX_CONTENT_LENGTH => $Config->sl_max_content_length || 131072; # 128k

my %default_headers = (
    'X-SLR' => 'aaaaaaaa|001c10090004',
    'Accept-Encoding' => 'gzip,deflate',
    'Accept-Charset'  => 'ISO-8859-1,utf-8;q=0.7,*;q=0.7',
    'Accept-Lang'     => 'en-us,en;q=0.5',
    'Accept' =>
'text/xml,application/xml,application/xhtml+xml,text/html;q=0.9,text/plain;q=0.8,image/png,*/*;q=0.5',
    'User-Agent' =>
'Mozilla/5.0 (Macintosh; U; Intel Mac OS X 10.5; en-US; rv:1.9.0.10) Gecko/2009042315 Firefox/3.0.10',
);

sub get {
    my ( $self, $args_ref ) = @_;
    unless ( $args_ref->{url} ) {
        warn("$$ no url passed, returning");
        return;
    }
    my $url  = $args_ref->{url};
    my $host = $args_ref->{host} || $args_ref->{headers}->{Host} || 'localhost';
    my $port = $args_ref->{port} || 80;

    $url = URI->new($url)
      or warn("Unable to parse url '$url'.") && return;

    my $headers = $args_ref->{headers} || \%default_headers;

    # convert headers to array-ref if a hash-ref is passed
    $headers = [%$headers] if ( ref $headers eq 'HASH' );

    my $http = Net::HTTP->new(
        Host     => $url->host,
        PeerAddr => $host,
        PeerPort => $port
    ) || die $@;

    # set keep alive
    $http->keep_alive(1);

    # reinforce the point (Net::HTTP adds PeerPort to host during
    # new())
    $http->host( $url->host );

    # make the request
    my $req = $url->path_query || "/";
    my $ok = $http->write_request( GET => $req, @$headers );

    # get the result code, message and response headers
    my ( $code, $mess, @headers_out ) = $http->read_response_headers;

    # read response body
    my $body = "";
    my $response = _build_response( $code, $mess, \@headers_out, \$body );

    # WHY is this here???
    # is this response html?
    #return unless $response->is_html;

    # is this response too big?
    my $content_length = $response->headers->header('Content-Length') || 0;
    if ( $content_length > MAX_CONTENT_LENGTH ) {
            warn("content length $content_length exceeds maximum limit") if DEBUG;
            return;
    }

    while (1) {

        my $buf;
        my $n = $http->read_entity_body( $buf, 10240 );
        die "read failed: $!" unless defined $n;
        last                  unless $n;
        $body .= $buf;

        if ( length($body) > MAX_CONTENT_LENGTH ) {
                warn("content length " . length($body) . " exceeds maximum limit")
                  if DEBUG;
                return;
        }
    }

    $response->content_ref( \$body );
    return $response;
}

# turns data returned by Net::HTTP into a HTTP::Response object
sub _build_response {
    my ( $code, $mess, $header_list, $body_ref ) = @_;

    my $header = HTTP::Headers->new(@$header_list);

    my $response = HTTP::Response->new( $code, $mess, $header, $$body_ref );
    return $response;
}

# adds a convenient extra method for inspection
{
    no warnings;
    *HTTP::Response::is_html = sub {
        return 1 if ( shift->content_type =~ m/text\/html/ );
        return;
    };

    *HTTP::Response::should_compress = sub {
        $" = '|';
        my @compressibles
          ;    # = qw( text/html text/xml text/plain application/pdf );
        return 1 if ( shift->content_type =~ m/(?:@compressibles)/ );
        return;
    };
}

1;
