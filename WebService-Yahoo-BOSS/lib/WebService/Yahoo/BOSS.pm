package WebService::Yahoo::BOSS;

=head1 NAME

WebService::Yahoo::BOSS - Interface to the Yahoo BOSS API

=cut

use strict;
use warnings;

use Any::Moose;
use Any::URI::Escape;
use LWP::UserAgent;
use URI;

our $VERSION  = '0.01';

our $Ua = LWP::UserAgent->new( agent => __PACKAGE__ . '_' . $VERSION );

our $api_host = 'boss.yahooapis.com';
our $api_base = "http://$api_host/";

has 'appid' => ( is => 'ro', isa => 'Str', required => 1 );
has 'url'   => ( is => 'ro', isa => 'Str', required => 1,
                 default => $api_base );

sub Web {
  my ($self, %args) = @_;

  return unless $args{q};
  my $format = $args{format} || 'xml';

  # build the endpoint
  my $url = URI->new($self->url . 'ysearch/web/v1/' . uri_escape($args{q}) .
                     '?appid=' . $self->appid . "&format=$format");

  my $res = $Ua->get($url);
  return unless $res->is_success;

  die "result is " . Dumper($res);


  return $res;
}


1;

=head1 SYNOPSIS

 use WebService::Yahoo::BOSS;

 # props out to the original boss Bruce Springsteen
 $Boss = WebService::Yahoo::BOSS->new( appid => $appid );

 $res = $Boss->Web( query   => 'microbrew award winner 2010',
                    exclude => 'pilsner', );

 # todo - add pluggable xml/json parser
 foreach my $hit ( @{$res ) {
     print $hit->url, $hit->title; # etc..
 }

=head1 DESCRIPTION

This API wraps the Yahoo BOSS (Build Your Own Search) web service API.

Mad props to Yahoo for putting out a premium search api which encourages
innovative use.

For more information check out the following links.  This is a work in
progress, so patches welcome!

The low level request structure is as follows:

 http://boss.yahooapis.com/ysearch/{vertical}/v1/{query}?appid=xyz[&param1=val1&param2=val2&etc]

=head1 SEE ALSO

 http://developer.yahoo.com/search/boss/boss_guide/overview.html

 L<Google::Search>

=head1 AUTHOR

"Fred Moyer", E<lt>fred@slwifi.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2010 by Silver Lining Networks

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.10.1 or,
at your option, any later version of Perl 5 you may have available.


=cut
