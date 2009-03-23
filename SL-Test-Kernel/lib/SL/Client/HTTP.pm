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


use URI;
use Net::HTTP;
use HTTP::Response;
use HTTP::Headers;
use Carp qw(croak);

sub reverse_get {
    my $pkg  = shift;
    my %args = @_;


    my $url = URI->new($args{url})
      or croak("Unable to parse url '$args{url}'.");
    my $host = $args{host};
    my $port = $args{port};
    my $headers = $args{headers} || [];

=cut
@$headers = (
'Keep-Alive','300',
'Connection', 'keep-alive',
'User-Agent','Mozilla/5.0 (Macintosh; U; Intel Mac OS X; en-US; rv:1.8.1.14) Gecko/20080404 Firefox/2.0.0.14',
'Accept', 'text/xml,application/xml,application/xhtml+xml,text/html;q=0.9,text/plain;q=0.8,image/png,*/*;q=0.5',
'Accept-Language', 'en-us,en;q=0.5',
'Accept-Encoding', 'gzip,deflate',
'Accept-Charset', 'ISO-8859-1,utf-8;q=0.7,*;q=0.7',
'Referer','http://www.yahoo.com/',
'Cookie', 'YM.CGP_phredwolf=res=1030x683; YM.stck=1208843759; YLS=v=1&db=1&p=0&n=9; Y=v=1&n=6blk3fq6fq2cn&l=f7h43meb5/o&p=m282rst053040000&jb=16|46|8&r=4o&lg=en&intl=us&np=1; F=a=mvpyhhIMvT1z0CRrj4hkLfyqoJv3GI9st0T7wmyohfUhchi0LORbevsO4AbdkURNUgMw7Yfq7HSEzsxnYLglgRhGkBbmhf2GZy15W6yLLjl5&b=2FJH; B=fdbe9fl40i99o&b=3&s=1d; sS=v=0&l=6kdj74h7kij%2Fo; YGCV=d=; PH=fn=tYHQ53KUF6o6e5h2K0jog59Y&l=en; T=z=j3XDIBjL/HIB90wIGAIyUgvMjM2BjEzMTc1MDBPNg--&a=YAE&sk=DAAjyGQPpUeLiS&ks=EAA6jATrs5sutElxCExCD5aFQ--~A&d=c2wBTlRReEFUWTBOakF5TnpjNE1RLS0BYQFZQUUBZwFwOGdCNGxJZVFIa0Y2ai5FMDEuQ01nLS0Bb2sBWlcwLQF0aXABWUk0aktDAXp6AWozWERJQkE3RQ--',
'Pragma','no-cache',
'Cache-Control','no-cache', );

=cut

$DB::single = 1;
    my $http = Net::HTTP->new(Host => $url->host,
                              PeerAddr => $host,
                              PeerPort => $port) || die $@;

    # reinforce the point (Net::HTTP adds PeerPort to host during
    # new())
    $http->host($url->host);
    if ($port == 8135) {
	$http->host($url->host . ":8135");
    }
    $http->keep_alive(1);
    
    # make the request
    #   my $req = $url->path_query || "/";
#    $http->write_request(GET => $req, @$headers);
#my $req = <<REQUEST;
#GET /mail/channel/bind?at=xn3j2v9hgz1alnhx0otznbju9f8xs7&VER=6&it=12&SID=C0430DDD724F9434&RID=48959&zx=klug2zrrl4rd&t=1 HTTP/1.1\cM\cJKeep-Alive: 300\cM\cJConnection: Keep-Alive\cM\cJHost: www.google.com\cM\cJUser-Agent: Mozilla/5.0 (Macintosh; U; Intel Mac OS X; en-US; rv:1.8.1.14) Gecko/20080404 Firefox/2.0.0.14\cM\cJAccept: text/xml,application/xml,application/xhtml+xml,text/html;q=0.9,text/plain;q=0.8,image/png,*/*;q=0.5\cM\cJAccept-Language: en-us,en;q=0.5\cM\cJAccept-Encoding: gzip,deflate\cM\cJAccept-Charset: ISO-8859-1,utf-8;q=0.7,*;q=0.7\cM\cJReferer: http://mail.google.com/mail/?ui=2&view=js&name=js&ids=qk1v6dmibzrk\cM\cJCookie: GX=DQAAAGsAAACotueScoPP4Wt5vJsbGK37KkhV2SdFBbvjSvEVq7rDHmTN_JCCpjIrdS3TBv3tbRpHU-HocBkluACGT3qzL6OUU7TzturonrfNKd3uuMEy_SSzfQSaXkW1GRK_QmnZV8QwNnS9VzsLK95EGZYN9Flu; S=awfe=GcnsPws49mWGAMb8XRLDFg:awfe-efe=GcnsPws49mWGAMb8XRLDFg:gmail=D2Tt1LWmB89K62cJp7D9Dw:gmail_yj=hrLSIzmthZSXlJyxuEyXSg:gmproxy=CSO98Ng0OQs:gmproxy_yj=AG8tk9rf35U:gmproxy_yj_sub=kDviJi4u3lY; GMAIL_AT=xn3j2v9hgz1alnhx0otznbju9f8xs7; gmailchat=fredmoyer\@gmail.com/961851; GMAIL_STAT_PENDING=/S:a=i&sv=&ev=tl&s=&t=2006&w=&e=m%3D0%2Cr%3D49%2Cj%3D117%2Cjl%3D824%2Cs%3D824%2Ci%3D825; NID=9=EnCf1ElfwdY7FR6lBSK6vj78UvwE6b4FfdPqb75ov2Lzsli4wyNeYWUXq1vxehWglUynKRU3xL7ytF2UTtZsLQqCcblRVODez8xOXmigBOJjux3vus-FHDO2cnFUwzgS; PREF=ID=da3faa1172b1ef8f:TM=1208565273:LM=1208565273:S=aQTdcy7-eb5PIFFC; S=awfe=GcnsPws49mWGAMb8XRLDFg:awfe-efe=GcnsPws49mWGAMb8XRLDFg; TZ=420; GMAIL_RTT=232;SID=DQAAAGcAAACnnGJ86f2FUnj45Y6sKCPJWg4tQpwoA2zeaQjKE5S22B4C8fFNxfaE7d7yfzJNNIWlo10ZIMMxmPK7JEiD3EBcjLxnER-nn4-HoZ3z2osIkyYmfIPQNCeHm8OZ2-98xFUFFfPhc1Af7G27vWV1rfqZ\cM\cJPragma: no-cache\cM\cJCache-Control: no-cache\cM\cJ\cM\cJ
#REQUEST


my $req = <<REQUEST;
GET /mail/channel/bind?at=xn3j2v9hgz1alnhx0otznbju9f8xs7&VER=6&it=12&SID=C0430DDD724F9434&RID=48959&zx=klug2zrrl4rd&t=1 HTTP/1.1\cM\cJHost: www.google.com\cM\cJKeep-Alive: 300\cM\cJConnection: Keep-Alive\cM\cJUser-Agent: Mozilla/5.0 (Macintosh; U; Intel Mac OS X; en-US; rv:1.8.1.14) Gecko/20080404 Firefox/2.0.0.14\cM\cJAccept: text/xml,application/xml,application/xhtml+xml,text/html;q=0.9,text/plain;q=0.8,image/png,*/*;q=0.5\cM\cJAccept-Language: en-us,en;q=0.5\cM\cJAccept-Encoding: gzip,deflate\cM\cJAccept-Charset: ISO-8859-1,utf-8;q=0.7,*;q=0.7\cM\cJReferer: http://mail.google.com/mail/?ui=2&view=js&name=js&ids=qk1v6dmibzrk\cM\cJCookie: GX=DQAAAGsAAACotueScoPP4Wt5vJsbGK37KkhV2SdFBbvjSvEVq7rDHmTN_JCCpjIrdS3TBv3tbRpHU-HocBkluACGT3qzL6OUU7TzturonrfNKd3uuMEy_SSzfQSaXkW1GRK_QmnZV8QwNnS9VzsLK95EGZYN9Flu; S=awfe=GcnsPws49mWGAMb8XRLDFg:awfe-efe=GcnsPws49mWGAMb8XRLDFg:gmail=D2Tt1LWmB89K62cJp7D9Dw:gmail_yj=hrLSIzmthZSXlJyxuEyXSg:gmproxy=CSO98Ng0OQs:gmproxy_yj=AG8tk9rf35U:gmproxy_yj_sub=kDviJi4u3lY; GMAIL_AT=xn3j2v9hgz1alnhx0otznbju9f8xs7; gmailchat=fredmoyer\@gmail.com/961851; GMAIL_STAT_PENDING=/S:a=i&sv=&ev=tl&s=&t=2006&w=&e=m%3D0%2Cr%3D49%2Cj%3D117%2Cjl%3D824%2Cs%3D824%2Ci%3D825; NID=9=EnCf1ElfwdY7FR6lBSK6vj78UvwE6b4FfdPqb75ov2Lzsli4wyNeYWUXq1vxehWglUynKRU3xL7ytF2UTtZsLQqCcblRVODez8xOXmigBOJjux3vus-FHDO2cnFUwzgS; PREF=ID=da3faa1172b1ef8f:TM=1208565273:LM=1208565273:S=aQTdcy7-eb5PIFFC; S=awfe=GcnsPws49mWGAMb8XRLDFg:awfe-efe=GcnsPws49mWGAMb8XRLDFg; TZ=420; GMAIL_RTT=232;SID=DQAAAGcAAACnnGJ86f2FUnj45Y6sKCPJWg4tQpwoA2zeaQjKE5S22B4C8fFNxfaE7d7yfzJNNIWlo10ZIMMxmPK7JEiD3EBcjLxnER-nn4-HoZ3z2osIkyYmfIPQNCeHm8OZ2-98xFUFFfPhc1Af7G27vWV1rfqZ\cM\cJPragma: no-cache\cM\cJCache-Control: no-cache\cM\cJ\cM\cJ
REQUEST

$http->print($req);

    # get the resulr code, message and response headers
    my ($code, $mess, @headers_out) = $http->read_response_headers;

    # read response body
    my $body = "";
    while (1) {
        my $buf;
        my $n = $http->read_entity_body($buf, 10240);
        die "read failed: $!" unless defined $n;
        last unless $n;
        $body .= $buf;
    }

    my $response = _build_response($code, $mess, \@headers_out, \$body);
    return $response;
}

# turns data returned by Net::HTTP into a HTTP::Response object
sub _build_response {
    my ($code, $mess, $header_list, $body_ref) = @_;

    my $header = HTTP::Headers->new(@$header_list);

    my $response = HTTP::Response->new($code, $mess, $header, $$body_ref);
    return $response;
}



sub get {
    my $pkg  = shift;
    my %args = @_;


    my $url = URI->new($args{url})
      or croak("Unable to parse url '$args{url}'.");
    my $host = $args{host};
    my $port = $args{port};
    my $headers = $args{headers} || [];

    $DB::single = 1;
    my $http = Net::HTTP->new(Host => $url->host,
                              PeerAddr => $host,
                              PeerPort => $port) || die $@;

    # reinforce the point (Net::HTTP adds PeerPort to host during
    # new())
    $http->host($url->host);
    if ($port == 8135) {
	$http->host($url->host . ":8135");
    }
    $http->keep_alive(1);
    
    # make the request
    my $req = $url->path_query || "/";
    $http->write_request(GET => $req, @$headers);

    # get the resulr code, message and response headers
    my ($code, $mess, @headers_out) = $http->read_response_headers;

    # read response body
    my $body = "";
    while (1) {
        my $buf;
        my $n = $http->read_entity_body($buf, 10240);
        die "read failed: $!" unless defined $n;
        last unless $n;
        $body .= $buf;
    }

    my $response = _build_response($code, $mess, \@headers_out, \$body);
    return $response;
}




1;
