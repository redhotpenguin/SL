package SL::Client::HTTP;
use strict;
use warnings;

=head1 NAME

SL::Client::HTTP - HTTP client for making requests to arbitrary host and port

=head1 SYNOPSIS

  use SL::Client::HTTP;

  # make a request through an SL proxy at 192.168.1.50:8069
  my $response = SL::Client::HTTP->get(
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

  $response = SL::Client::HTTP->get(
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

use Params::Validate qw(validate HASHREF);
use URI;
use Net::HTTP;
use HTTP::Response;
use HTTP::Headers;
use Carp qw(croak);

my %default_headers = (
    'Accept-Encoding' => 'gzip,deflate',
    'Accept-Charset'  => 'ISO-8859-1,utf-8;q=0.7,*;q=0.7',
    'Keep-Alive'      => 300,
    'Connection'      => 'keep-alive',
    'Pragma'          => 'no-cache',
    'Cache-Control'   => 'no-cache',
    'Accept-Lang'     => 'en-us,en;q=0.5',
    'Accept'          =>
'text/xml,application/xml,application/xhtml+xml,text/html;q=0.9,text/plain;q=0.8,image/png,*/*;q=0.5',
    'User-Agent' =>
'Mozilla/5.0 (Macintosh; U; PPC Mac OS X Mach-O; en-US; rv:1.8.0.2) Gecko/20060308 Firefox/1.5.0.2',
);

sub get {
    my $pkg  = shift;
    my %args = validate(
        @_,
        {
            url     => 1,
            host    => 1,
            port    => 1,
            headers => 0,
        }
    );

    my $url = URI->new( $args{url} )
      or croak("Unable to parse url '$args{url}'.");
    my $host    = $args{host};
    my $port    = $args{port};
    my $headers = $args{headers} || \%default_headers;

    # convert headers to array-ref if a hash-ref is passed
    $headers = [%$headers] if ( ref $headers eq 'HASH' );

    # setup some default headers
    my %seen_keys;
    for my $i ( 0 .. $#$headers ) {
        $seen_keys{ $headers->[$i] }++ if ( ( $i % 2 ) == 0 );
    }

    my $http = Net::HTTP->new(
        Host     => $url->host,
        PeerAddr => $host,
        PeerPort => $port
      )
      || die $@;

    # reinforce the point (Net::HTTP adds PeerPort to host during
    # new())
    $http->host( $url->host );

    # make the request
    my $req = $url->path_query || "/";
    $http->write_request( GET => $req, @$headers );

    # get the resulr code, message and response headers
    my ( $code, $mess, @headers_out ) = $http->read_response_headers;

    # read response body
    my $body = "";
    while (1) {
        my $buf;
        my $n = $http->read_entity_body( $buf, 10240 );
        die "read failed: $!" unless defined $n;
        last                  unless $n;
        $body .= $buf;
    }

    my $response = _build_response( $code, $mess, \@headers_out, \$body );
    return $response;
}

# turns data returned by Net::HTTP into a HTTP::Response object
sub _build_response {
    my ( $code, $mess, $header_list, $body_ref ) = @_;

    my $header = HTTP::Headers->new(@$header_list);

    my $response = HTTP::Response->new( $code, $mess, $header, $$body_ref );
    return $response;
}

1;
