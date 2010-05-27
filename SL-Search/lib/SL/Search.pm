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
use Carp                ();
use Data::Dumper qw(Dumper);

use constant DEBUG         => $ENV{SL_SEARCH_DEBUG}  || 0;
use constant VERBOSE_DEBUG => $ENV{SL_VERBOSE_DEBUG} || 0;

my $sf_adserver_side = <<'ADSIDE';
<a href="http://www.spotfocus.com/"><img src="http://spotfocus.com/Images/Spot_Logo_Header_trans.gif"></a>
ADSIDE


my $sl_adserver_side = <<'ADSIDE';
<script type='text/javascript'><!--//<![CDATA[
   var m3_u = (location.protocol=='https:'?'https://ads.slwifi.com/www/delivery/ajs.php':'http://ads.slwifi.com/www/delivery/ajs.php');
   var m3_r = Math.floor(Math.random()*99999999999);
   if (!document.MAX_used) document.MAX_used = ',';
document.write ("<scr"+"ipt type='text/javascript' src='"+m3_u);
document.write ("?zoneid=44");
document.write ('&amp;cb=' + m3_r);
if (document.MAX_used != ',') document.write ("&amp;exclude=" + document.MAX_used);
document.write (document.charset ? '&amp;charset='+document.charset : (document.characterSet ? '&amp;charset='+document.characterSet : ''));
document.write ("&amp;loc=" + escape(window.location));
if (document.referrer) document.write ("&amp;referer=" + escape(document.referrer));
if (document.context) document.write ("&context=" + escape(document.context));
if (document.mmm_fo) document.write ("&amp;mmm_fo=1");
document.write ("'><\/scr"+"ipt>");
//]]>--></script><noscript><a href='http://ads.slwifi.com/www/delivery/ck.php?n=a82c0627&amp;cb=INSERT_RANDOM_NUMBER_HERE' target='_blank'><img src='http://ads.slwifi.com/www/delivery/avw.php?zoneid=44&amp;n=a82c0627' border='0' alt='' /></a></noscript>
ADSIDE

my $uw_adserver_side = <<'ADSIDE';
<script type='text/javascript'><!--//<![CDATA[
    var m3_u = (location.protocol=='https:'?'https://www.urbanwireless.net/adserver/www/delivery/ajs.php':'http://www.urbanwireless.net/adserver/www/delivery/ajs.php');
    var m3_r = Math.floor(Math.random()*99999999999);
    if (!document.MAX_used) document.MAX_used = ',';
    document.write ("<scr"+"ipt type='text/javascript' src='"+m3_u);
    document.write ("?zoneid=60");
    document.write ('&amp;cb=' + m3_r);
    if (document.MAX_used != ',') document.write ("&amp;exclude=" + document.MAX_used);
    document.write (document.charset ? '&amp;charset='+document.charset : (document.characterSet ? '&amp;charset='+document.characterSet : ''));
    document.write ("&amp;loc=" + escape(window.location));
    if (document.referrer) document.write ("&amp;referer=" + escape(document.referrer));
    if (document.context) document.write ("&context=" + escape(document.context));
    if (document.mmm_fo) document.write ("&amp;mmm_fo=1");
    document.write ("'><\/scr"+"ipt>");
    //]]>--></script><noscript><a href='http://www.urbanwireless.net/adserver/www/delivery/ck.php?n=a945d503&amp;cb=5013710012' target='_blank'><img src='http://www.urbanwireless.net/adserver/www/delivery/avw.php?zoneid=60&amp;cb=5013710012&amp;n=a945d503' border='0' alt='' /></a></noscript>
ADSIDE
    

# temp bullshit
our %Vhosts = (
    'search.slwifi.com' => {
        account_name     => 'Silver Lining',
        account_website  => 'http://www.slwifi.com/',
        gsearch_referrer => 'http://www.silverliningnetworks.com/index.html',
        gsearch_key =>
'ABQIAAAAt99bvP994xq9YNIdB2-NFxRoGs5M4h5stXbFY-B98U2dj3BFJxTyPyzVnLw_SKtAXQeZ0B7OiGWElQ',

        # in progress
        linkshare_api =>
          '4e5c9767680b23d7965887f50f25a6ff17ddc1fcb1bc2f6df7cf8c493aead77c',

        search_logo => 'http://s.slwifi.com/images/logos/sl_logo_small.png',
        citygrid_api_key => 'xt8fua382xpg6sdt3zwynuvq',
        citygrid_where  => '94109',
        citygrid_publisher => 'slnetworks',
        adserver_side => $sl_adserver_side,
    },

    'search.urbanwireless.net' => {
        account_name     => 'Urban Wireless',
        account_website  => 'http://www.urbanwireless.net',
        gsearch_referrer => 'http://www.urbanwireless.net/tos.html',
        gsearch_key =>
'ABQIAAAAt99bvP994xq9YNIdB2-NFxT1C8xMKBm2uaMFjGyMDlpu1AwWNxR6u5j0td4nhB0zNeALaEIHJPB3QQ',

        linkshare_api =>
          'ece9b8630351548eaf66fade91653f9d05826e7052a4be7e1acec82c62d3931d',

        search_logo => 'http://s.slwifi.com/images/logos/urbanwireless.png',

        citygrid_api_key => 'ba87j9x45p3jc4fvb8yxgag9',
        citygrid_where  => '72201',
        citygrid_publisher => 'urbanwireless',
        adserver_side => $uw_adserver_side,
    },

    'occ.slwifi.com' => {
        account_name     => 'Oregon Convention Center',
        account_website  => 'http://www.oregoncc.org/',
        gsearch_referrer => 'http://www.silverliningnetworks.com/index.html',
        gsearch_key =>
'ABQIAAAAt99bvP994xq9YNIdB2-NFxRoGs5M4h5stXbFY-B98U2dj3BFJxTyPyzVnLw_SKtAXQeZ0B7OiGWElQ',

        search_logo => 'http://www.oregoncc.org/images/topphoto2.gif',
        citygrid_api_key => 'xt8fua382xpg6sdt3zwynuvq',
        citygrid_where  => '97232',
        citygrid_publisher => 'slnetworks',
        adserver_side => $sf_adserver_side,
 

    }
);


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

            $hash{'content'} = eval { $self->force_utf8( $hash{'content'} ) };
	    warn($@) if ($@ && DEBUG);
        }

        my $title = $hash{'title'};
        if ( defined $hash{'title'} ) {
            $hash{'title'} = eval { $self->force_utf8( $hash{'title'} ) };
	    warn($@) if ($@ && DEBUG);
        }

        unless ( $hash{'visibleUrl'} =~ m{/} ) {

            $hash{'visibleUrl'} .= '/';
        }

        $hash{'url'} = $hash{'unescapedUrl'};

        push @search_results, \%hash;
    }

    return \@search_results;
}

sub force_utf8 {
    my ( $self, $string ) = @_;

    if ( ref( Encode::Guess::guess_encoding($string) ) ) {

        $string = eval { Encode::Guess::decode( "Guess", $string, 0 ) };
	if ($@) {
		die("could not guess decode for $string");
	}
    }
    else {

        $string = Encode::decode( 'utf8', $string, 0 );
	if ($@) {
		die("could not decode utf8 for $string");
	}
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

