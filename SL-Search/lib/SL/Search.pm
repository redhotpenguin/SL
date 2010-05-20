package SL::Search;

use strict;
use warnings;

=head1 NAME

SL::Search - Handles searches for Silver Lining virtual hosts

=cut

our $VERSION = 0.01;

use Google::Search      ();
use Encode              ();
use Encode::Guess qw/euc-jp shiftjis 7bit-jis/;
use WebService::VigLink ();
use Digest::MD5         ();
use Carp                ();
use Data::Dumper qw(Dumper);
use Net::Amazon                ();
use Net::Amazon::Request::All  ();
use Net::Amazon::Response::All ();

use constant DEBUG         => $ENV{SL_SEARCH_DEBUG}  || 0;
use constant VERBOSE_DEBUG => $ENV{SL_VERBOSE_DEBUG} || 0;

# temp bullshit
our %Vhosts = (
    'search.slwifi.com' => {
        account_name     => 'Silver Lining',
        account_website  => 'http://www.slwifi.com/',
        gsearch_referrer => 'http://www.silverliningnetworks.com/index.html',
        gsearch_key =>
'ABQIAAAAt99bvP994xq9YNIdB2-NFxRoGs5M4h5stXbFY-B98U2dj3BFJxTyPyzVnLw_SKtAXQeZ0B7OiGWElQ',

        # crappy returns
        chitika_id => 'silverlining',

        # low payout
        viglink_apikey => 'c93c31688caea7b9cef80e101a9458e8',

        # in progress
        linkshare_api =>
          '4e5c9767680b23d7965887f50f25a6ff17ddc1fcb1bc2f6df7cf8c493aead77c',

        # Amazon.  Non-starter because no search engines allowed in Amazon TOS
        aws_id => 'sillinseapor-20',
        aws_ua => Net::Amazon->new(
            token      => '11KEP8CKMDE38S9A8EG2',
            secret_key => 'fal/qogvs0sA9ZgwYJdfW/H0kmnzpyLcCNylhvr6',
            max_pages  => 1
        ),
        search_logo => 'http://s.slwifi.com/images/logos/sl_logo_small.png',
    },

    'search.urbanwireless.net' => {
        account_name     => 'Urban Wireless',
        account_website  => 'http://www.urbanwireless.net',
        gsearch_referrer => 'http://www.urbanwireless.net/tos.html',
        gsearch_key =>
'ABQIAAAAt99bvP994xq9YNIdB2-NFxT1C8xMKBm2uaMFjGyMDlpu1AwWNxR6u5j0td4nhB0zNeALaEIHJPB3QQ',
        chitika_id     => 'urbanwireless',
        viglink_apikey => '1ce7984ceec563945297aa68b7fbed11',
        linkshare_api =>
          'ece9b8630351548eaf66fade91653f9d05826e7052a4be7e1acec82c62d3931d',
        search_logo =>
'http://www.urbanwireless.net/wp-content/themes/urban-view/images/urbanweblogo.png',
        citygrid_apikey => 'xt8fua382xpg6sdt3zwynuvq',
    },
);

=over 4 AMAZON


=cut

our $amazon_href = 'http://www.amazon.com/gp/product/%s/?tag=%s';

sub amazon_ads {
    my ( $self, $q ) = @_;

    my $req = Net::Amazon::Request::All->new(
        all  => $q,
        page => 1,
        type => 'Medium',
    );

    my $resp = $self->{aws_ua}->request($req);

    return unless $resp->is_success;

    my @results;
    my $i = 0;
    for my $property ( $resp->properties ) {

        my $desc = substr( $property->ProductDescription, 0, 175 );
        next unless $desc;
        next if $desc =~ m/(?:<)/;    # no html characters please
        next unless $property->ListPrice;
        push @results,
          {
            name        => $property->ProductName,
            asin        => $property->ASIN,
            group       => $property->Catalog,
            price       => $property->ListPrice,
            description => $desc . '...',
            href => sprintf( $amazon_href, $property->ASIN, $self->{aws_id} ),
          };
        last if ++$i == 3;
    }

    return \@results;
}

sub vhost {
    my ( $class, $args ) = @_;

    die 'need a hostname' unless $args->{host};

    return unless defined $Vhosts{ $args->{host} };

    my %self = %{ $Vhosts{ $args->{host} } };
    bless \%self, $class;

    return \%self;
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

            #$hash{'content'} = Encode::decode_utf8( $hash{'content'} );
            $hash{'content'} = $self->force_utf8( $hash{'content'} );
        }

        my $title = $hash{'title'};
        if ( defined $hash{'title'} ) {
            $hash{'title'} = $self->force_utf8( $hash{'title'} );
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
                txt      => Encode::encode_utf8($title),
                title    => $self->{account_name}
                  . " - Custom Search for '"
                  . $search_args->{q} . "'",
            }
        );

        push @search_results, \%hash;
    }

    return \@search_results;
}

sub force_utf8 {
    my ( $self, $string ) = @_;

    if ( ref( Encode::Guess::guess_encoding($string) ) ) {

        $string = Encode::Guess::decode( "Guess", $string, 0 );
    }
    else {

        $string = Encode::decode( 'utf8', $string );
    }

    return $string;
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

