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
use WebService::Yahoo::BOSS::ResultSet;

our $VERSION = '0.03';

our $Ua = LWP::UserAgent->new( agent => __PACKAGE__ . '_' . $VERSION );

our $Api_host = 'boss.yahooapis.com';
our $Api_base = "http://$Api_host/";

has 'appid' => ( is => 'ro', isa => 'Str', required => 1 );
has 'url' => (
    is       => 'ro',
    isa      => 'Str',
    required => 1,
    default  => $Api_base,
);

sub Web {
    my ( $self, %args ) = @_;

    unless ($args{query} && ($args{query} ne '')) {
        die "query param needed to search";
    }

    my $format = $args{format} || 'xml';
    die 'only xml format supported, patches welcome' unless $format eq 'xml';

    # build the endpoint
    my $urlstring = $self->url
          . 'ysearch/web/v1/'
          . uri_escape( $args{query} )
          . '?appid='
          . $self->appid
          . "&format=$format&filter=-porn&view=keyterms";

    if ($args{start}) {
        $urlstring .= "&start=" . $args{start};
    }

    my $url = URI->new($urlstring);

    my $res = $Ua->get($url);
    unless ( $res->is_success ) {
        die $res->status_line;
    }

    my $result_set = WebService::Yahoo::BOSS::ResultSet->parse(
        $res->decoded_content);

    return $result_set;
}

1;

=head1 SYNOPSIS

 use WebService::Yahoo::BOSS;

 # props out to the original boss Bruce Springsteen
 $Boss = WebService::Yahoo::BOSS->new( appid => $appid );

 $res = $Boss->Web( query   => 'microbrew award winner 2010',
                    start   => 0,
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
