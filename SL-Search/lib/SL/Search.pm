package SL::Search;

use strict;
use warnings;

=head1 NAME

SL::Search - Handles searches for Silver Lining virtual hosts

=cut

our $VERSION = 0.01;

use Google::Search      ();
use Encode              ();
use WebService::VigLink ();
use Digest::MD5         ();
use Carp                ();

use constant DEBUG         => $ENV{SL_DEBUG}         || 0;
use constant VERBOSE_DEBUG => $ENV{SL_VERBOSE_DEBUG} || 0;

# temp bullshit
our %Vhosts = (
    'search.slwifi.com' => {
        account_name     => 'Silver Lining',
        account_website  => 'http://www.slwifi.com/',
        gsearch_referrer => 'http://www.silverliningnetworks.com/index.html',
        gsearch_key =>
'ABQIAAAAt99bvP994xq9YNIdB2-NFxRoGs5M4h5stXbFY-B98U2dj3BFJxTyPyzVnLw_SKtAXQeZ0B7OiGWElQ',
        chitika_id     => 'silverlining',
        viglink_apikey => 'c93c31688caea7b9cef80e101a9458e8',
        linkshare_api =>
          '4e5c9767680b23d7965887f50f25a6ff17ddc1fcb1bc2f6df7cf8c493aead77c',
    },
    'search.urbanwireless.net' => {
        account_name     => 'Urban Wireless',
        account_website  => 'http://www.urbanwireless.net',
        gsearch_referrer => 'http://www.urbanwireless.net/tos.html',
        gsearch_key =>
'ABQIAAAAt99bvP994xq9YNIdB2-NFxT1C8xMKBm2uaMFjGyMDlpu1AwWNxR6u5j0td4nhB0zNeALaEIHJPB3QQ',
        chitika_id     => 'urbanwireless',
        viglink_apikey => '1ce7984ceec563945297aa68b7fbed11',
        linkshare_api  => '',
    },
);

sub vhost {
    my ( $class, $args ) = @_;

    die 'need a hostname' unless $args->{host};

    my $self = $Vhosts{ $args->{host} };
    bless $self, $class;

    return $self;
}

sub default_vhost {
    my $class = shift;

    return $class->vhost( { host => 'search.slwifi.com' } );
}

sub search {
    my ( $self, $search_args ) = @_;

    $search_args->{key}      = $self->{gsearch_key};
    $search_args->{referrer} = $self->{gsearch_referrer};
    my $search = eval { Google::Search->Web( %{$search_args} ) };
    die $@ if $@;

    my $viglink =
      WebService::VigLink->new( { 'key' => $self->{viglink_apikey} } );

    my $i     = 1;
    my $limit = 10;
    my @search_results;
    while ( my $result = $search->next ) {

        warn( "search result: " . Dumper($result) ) if DEBUG;

        last if ++$i > $limit;
        my %hash = map { $_ => $result->{_content}->{$_} }
          keys %{ $result->{_content} };

        if ( defined $hash{'content'} ) {
            my $content = $hash{'content'};
            $hash{'content'} =
              eval { Encode::decode( 'utf8', $hash{'content'} ) };

            if ($@) {
                Carp::carp( "encoding error: $@ for " . $hash{'content'} );
                $hash{'content'} = $content;
            }
        }

        if ( defined $hash{'title'} ) {
            my $title = $hash{'title'};
            $hash{'title'} = eval { Encode::decode( 'utf8', $hash{'title'} ) };

            if ($@) {

                Carp::carp( "encoding error: $@ for title " . $hash{'title'} );
                $hash{'title'} = $title;
            }
        }

        unless ( $hash{'visibleUrl'} =~ m{/} ) {

            $hash{'visibleUrl'} .= '/';
        }

        $hash{'url'} = $viglink->make_url(
            {
                out      => $hash{'unescapedUrl'},
                cuid     => Digest::MD5::md5_hex( $search_args->{remote_ip} ),
                loc      => $search_args->{url},
                referrer => $search_args->{referrer},
                txt      => $hash{'title'},
                title    => $self->{account_name}
                  . " - Custom Search for '"
                  . $search_args->{q} . "'",
            }
        );

        push @search_results, \%hash;
    }

    return \@search_results;
}

1;

=head1 SYNOPSIS

 $search_vhost = SL::Search->vhost({ host => "search.urbanwireless.net" });

=head1 DESCRIPTION

Does searching.

=head1 AUTHOR

Fred Moyer <fred@slwifi.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2010 by Silver Lining Networks.

This software is proprietary under the Silver Lining Networks software license.

=cut

