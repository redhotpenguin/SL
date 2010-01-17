package SL::Model::Proxy::Ad;

use strict;
use warnings;

use base 'SL::Model';

use Template   ();
use SL::Config ();
use SL::Cache  ();

=head1 NAME

SL::Model::Ad

=head1 DESCRIPTION

This serves ads, ya see?

=cut

use Data::Dumper;
use constant DEBUG => $ENV{SL_DEBUG} || 0;
use constant AD_TIMEOUT => 300; # 5 minute cache timeout for ads

our ( $Config, $Tmpl, $Leaderboard );

# memcached data structure mapping
# thou shalt not change schema without thinking first
# else I will hit you with a stick ;)
#
# router|$router_id|brandings      = [ $zone_id => $zone1_weight, .. ];
# router|$router_id|splashes       = [ $zone_id => $zone1_weight, .. ];
# router|$router_id|persistents    = [ $zone_id => $zone1_weight, .. ];
# router|$router_id|sized          = [ $zone_id => $zone1_weight, .. ];
#
# router|$router_id                = { account_id => $a, mac => $m, lan_ip => $l };
# router|$router_mac               = $router_id;

# account|$account_id|persistents = [ $zone_id => $zone1_weight, .. ];
# account|$account_id|brandings   = [ $zone_id => $zone1_weight, .. ];
# account|$account_id|sized       = [ $zone_id => $zone1_weight, .. ];
# account|$account_id            = { advertise_here => $a, aaa => $b, marketplace => $m };
#
# adzone|$zone_id                = $zone_content;
#
# location|$ip                   = [ { 'FF:FF:FF:FF:FF:FF' => '2001-06-01 00:00:00' },
#                                    { $device2_mac => .. }, ];

BEGIN {
    $Config = SL::Config->new;

    my $path = $Config->sl_root . '/tmpl/';
    die "Template include path $path doesn't exist!\n" unless -d $path;

    my $tmpl_config = { ABSOLUTE => 1, INCLUDE_PATH => $path, };
    $Tmpl = Template->new($tmpl_config) || die $Template::ERROR,;

    $Leaderboard = { ad_size_id => 1,
                     css_url => 'http://s2.slwifi.com/css/sl_leaderboard.css',
                     js_url  => 'http://s2.slwifi.com/js/horizontal.js',
                     head_html => '',
                     template => 'horizontal_leaderboard.tmpl', };

}

=head1 METHODS

=over 4

=item C<container( $css_url, $response, $ad )>

Method for ad insertion which wraps the whole page in a stylesheet

=cut

our (
    $html_regex, $head_regex,     $start_body_regex,
    $uber_match, $end_body_match, $tail
);

BEGIN {
    $tail = qq{</div>}
      ; #<script type='text/javascript' src='http://www.othersonline.com/partner/scripts/silver-lining-networks-inc/alice.js'></script>};

    $head_regex = qr{^(.*?<\s*?head\s*?[^>]*?>)(.*)$}is;    # start of head
        #$head_regex          = qr{^(.*)(<\s*?\/head\s*?>.*)$}is;  # end of head
    $uber_match       = qr{\G(?:</\s*?head\s*?>)}i;
    $start_body_regex = qr{\G(.*?)<body([^>]*?)>(.*)$}is;
    $end_body_match   = qr{^(.*)(<\s*?/body\s*?>.*)$}is;
    $html_regex       = qr{^(.*?<\s*?html[^>]*?>)(.*)$}is;
}

our $HEAD = <<HEAD;
<script type="text/javascript" src="%s"></script>
<link rel="stylesheet" type="text/css" href="%s" />%s
HEAD

sub container {
    my ( $css_url_ref, $js_url_ref, $head_html_ref, $decoded_content_ref,
        $ad_ref )
      = @_;

    # check to make sure that we can insert all parts of the ad
    return
      unless ( ( $$decoded_content_ref =~ m/$head_regex/ )
        && ( $$decoded_content_ref =~ m/$start_body_regex/ ) );

    if ( !defined $$head_html_ref ) {
        $$head_html_ref = '';
    }

    # build the head content
    my $head = sprintf( "$HEAD", $$js_url_ref, $$css_url_ref, $$head_html_ref );

    # Insert the head content
    my $matched = $$decoded_content_ref =~ s{$head_regex}{$1$head$2};
    warn('failed to insert head content') unless $matched;

  # move the pointer to the end of the head tag - optimization, 0.5 milliseconds
    $$decoded_content_ref =~ m/$uber_match/;

    # Insert the rest of the pieces
    $matched = $$decoded_content_ref =~ s{$start_body_regex}
                         {$1<body$2>$$ad_ref$3};
    warn( 'failed to insert ad content ' . $$ad_ref ) unless $matched;

    # insert the tail
    $matched = $$decoded_content_ref =~ s{$end_body_match}{$1$tail$2};
    warn('failed to insert closing div') if ( DEBUG && !$matched );

    return 1;
}

# grabs the default persistents for an account
sub retrieve_account_default_persistents {
    my ( $class, $account_id ) = @_;

    my $ad_data = $class->connect->selectall_arrayref(
        <<SQL, { Slice => {} }, $account_id );
SELECT
ad_zone.ad_zone_id,
ad_zone.weight
FROM ad_zone
WHERE ad_zone.account_id  = ?
AND ad_zone.is_default = 't'
AND ad_zone.active = 't'
AND ad_zone.ad_size_id IN (1,10,12,23)
SQL

    unless ( $ad_data->[0] ) {
        warn("no account default persistents, account $account_id!") if DEBUG;
        return;
    }

    warn( "got account default persistent " . Dumper($ad_data) )
      if DEBUG;

    return $ad_data;
}

# grabs the default brandings for an account
sub retrieve_account_default_brandings {
    my ( $class, $account_id ) = @_;

    my $ad_data = $class->connect->selectall_arrayref(
        <<SQL, { Slice => {} }, $account_id );
SELECT
ad_zone.ad_zone_id,
ad_zone.weight
FROM ad_zone
WHERE ad_zone.account_id = ?
AND ad_zone.is_default = 't'
AND ad_zone.active = 't'
AND ad_zone.ad_size_id IN (20,22,24)
SQL

    unless ( $ad_data->[0] ) {
        warn("no default brandings for account $account_id!") if DEBUG;
        return;
    }

    warn( "got account default branding " . Dumper($ad_data) )
      if DEBUG;

    return $ad_data;
}

# returns the ad ids of the account zones
sub account_default_ad_zones {
    my ( $class, $account_id ) = @_;

    require Carp && Carp::confess unless $account_id;

    my $persistents = $class->account_default_persistents($account_id)
      || return;

    my $brandings = $class->account_default_brandings($account_id) || return;

    return ( $persistents, $brandings );
}

sub account_default_persistents {
    my ( $class, $account_id ) = @_;

    require Carp && Carp::confess unless $account_id;

    warn("grabbing account default persistents") if DEBUG;

    my $persistents =
      SL::Cache->memd->get("account|$account_id|persistents");

    unless ($persistents) {

        # go to the database
        $persistents =
          $class->retrieve_account_default_persistents($account_id);

        return unless $persistents;

        # update the cache
        SL::Cache->memd->set(
            "account|$account_id|persistents" => $persistents,
            AD_TIMEOUT        );
    }

    return $persistents;
}

# returns the ad ids of the account default branding zones
sub account_default_brandings {
    my ( $class, $account_id ) = @_;

    warn("grabbing account default brandings") if DEBUG;

# grab the default branding images
# adzone|$account_id|default_branding = [ $persistent_zone_id_1 => $zone1_weight, .. ];
    my $brandings =
      SL::Cache->memd->get("account|$account_id|brandings");

    unless ($brandings) {

        warn("no cached brandings account $account_id") if DEBUG;
        # go to the database
        $brandings = $class->retrieve_account_default_brandings($account_id);

        return unless $brandings;

        # update the cache
        SL::Cache->memd->set(
            "account|$account_id|brandings" => $brandings,
            AD_TIMEOUT
        );
    }

    return $brandings;
}

sub retrieve_router_persistents {
    my ( $class, $router_id ) = @_;

    my $ad_data =
      $class->connect->selectall_arrayref( <<SQL, { Slice => {} }, $router_id );
SELECT
ad_zone.ad_zone_id,
ad_zone.weight
FROM ad_zone,router__ad_zone
WHERE router__ad_zone.router_id = ?
AND ad_zone.active = 't'
AND ad_zone.ad_size_id IN (1,10,12,23)
AND router__ad_zone.ad_zone_id = ad_zone.ad_zone_id
SQL

    unless ( $ad_data->[0] ) {
        warn("no persistent ads for router $router_id!") if DEBUG;
        return;
    }

    warn( "retrieved router persistent " . Dumper($ad_data) ) if DEBUG;

    return $ad_data;
}

sub retrieve_router_brandings {
    my ( $class, $router_id ) = @_;

    my $ad_data =
      $class->connect->selectall_arrayref( <<SQL, { Slice => {} }, $router_id );
SELECT
ad_zone.ad_zone_id,
ad_zone.weight
FROM ad_zone,router__ad_zone
WHERE router__ad_zone.router_id = ?
AND ad_zone.active = 't'
AND ad_zone.ad_size_id IN ( 20,22,24 )
AND router__ad_zone.ad_zone_id = ad_zone.ad_zone_id
SQL

    unless ( $ad_data->[0] ) {
        warn("no retrieve router brandings for router $router_id") if DEBUG;
        return;
    }

    warn( "retrieved got router branding " . Dumper($ad_data) ) if DEBUG;

    return $ad_data;
}

sub router_ad_zones {
    my ( $class, $router_id, $account_id ) = @_;

    my $persistents = $class->router_persistents( $router_id, $account_id )
      || return;

    my $brandings = $class->router_brandings( $router_id, $account_id )
      || return;

    return ( $persistents, $brandings );
}

sub router_persistents {
    my ( $class, $router_id, $account_id ) = @_;

    my $persistents = SL::Cache->memd->get("router|$router_id|persistents");

    unless ($persistents) {

        warn("no cached persistents router $router_id") if DEBUG;
        $persistents = $class->retrieve_router_persistents($router_id);

        unless ($persistents) {
            warn("no persistents for router $router_id") if DEBUG;
            return;
        }

        # update the cache, five minute timeout
        SL::Cache->memd->set(
            "router|$router_id|persistents" => $persistents,
            AD_TIMEOUT
        );
    } else {

        warn("found router $router_id cached persistents") if DEBUG;
    }

    return $persistents;
}

sub router_brandings {
    my ( $class, $router_id, $account_id ) = @_;

    my $brandings = SL::Cache->memd->get("router|$router_id|brandings");
    unless ($brandings) {

        warn("no cached brandings router $router_id") if DEBUG;
        $brandings = $class->retrieve_router_brandings($router_id);

        unless ($brandings) {
            warn("no brandings for router $router_id") if DEBUG;
            return;
        }

        # update the cache, 5 minute expire
        SL::Cache->memd->set( "router|$router_id|brandings" => $brandings,
                              AD_TIMEOUT );
    } else {
        warn("found router $router_id cached brandings") if DEBUG;
    }

    return $brandings;
}

sub get_ad_zone {
    my ( $class, $ad_zone_id ) = @_;

    # check the cache for the ad zone
    my $ad_data = SL::Cache->memd->get("ad_zone|$ad_zone_id");

    unless ($ad_data) {

        # grab it from the database
        $ad_data = $class->retrieve_ad_zone($ad_zone_id);
        die "missing ad zone $ad_zone_id" unless $ad_data;

        SL::Cache->memd->set( "ad_zone|$ad_zone_id" => $ad_data, AD_TIMEOUT );
    }

    return $ad_data;
}

sub retrieve_ad_zone {
    my ( $class, $ad_zone_id ) = @_;

    my $ad_data = $class->connect->selectrow_hashref( <<SQL, {}, $ad_zone_id );
SELECT
ad_zone.ad_zone_id,
ad_zone.weight,
ad_zone.code,
ad_zone.image_href,
ad_zone.link_href,
ad_zone.ad_size_id,
ad_size.head_html,
ad_size.js_url,
ad_size.css_url,
ad_size.template
FROM ad_zone,ad_size
WHERE ad_zone.ad_zone_id = ?
AND ad_size.ad_size_id = ad_zone.ad_size_id
SQL

    return unless $ad_data;
    return $ad_data;
}

sub get_account {
    my ( $class, $account_id ) = @_;

    my $account = $class->connect->selectrow_hashref( <<SQL, {}, $account_id );
SELECT
aaa,advertise_here
FROM account
WHERE account_id = ?
SQL

    return unless $account;
    return $account;
}

sub get_router {
    my ( $class, $router_id ) = @_;

    my $router = $class->connect->selectrow_hashref( <<SQL, {}, $router_id );
SELECT
lan_ip
FROM router
WHERE router_id = ?
SQL

    return unless $router;
    return $router;
}

# silverlining ad dispatcher
# this method returns a random ad, given the id of the router

sub random {
    my ( $class, $args ) = @_;

    my $url       = $args->{url}       || warn("no url passed")  && return;
    my $router_id = $args->{router_id} || warn("no router_id")   && return;
    my $user      = $args->{user}      || warn("no user passed") && return;
    my $ua        = $args->{ua}        || warn("no ua passed")   && return;
    my $ip        = $args->{ip}        || warn("no ip passed")   && return;
    my $device_guess = $args->{device_guess};

    my $device = SL::Model::Proxy::Router->get($router_id)
      || warn("no router for id $router_id") && return;

    my $account_id = $device->{account_id};

    # grab the ads specific to this device
    warn("grabbing ads for router $router_id") if DEBUG;
	my ($persistents, $brandings) =
            $class->router_ad_zones( $router_id, $account_id );

    unless ($persistents && $brandings) {

		warn("grabbing default ads account $account_id, router $router_id") if DEBUG;
		($persistents, $brandings) =
            $class->account_default_ad_zones( $account_id );
    }

    unless ( $persistents && $brandings ) {

        warn("no ads for router $router_id, account $account_id");
        return;
    }

    # grab a weighted random ad
    my @persistents_list;
    foreach my $ad_zone ( @{$persistents} ) {
        push @persistents_list, $ad_zone->{ad_zone_id}
          for 1 .. $ad_zone->{weight};
    }

    my $persistent_id =
      $persistents_list[ int( rand( scalar(@persistents_list) ) ) ];

    my @brandings_list;
    foreach my $ad_zone ( @{$brandings} ) {
        push @brandings_list, $ad_zone->{ad_zone_id}
          for 1 .. $ad_zone->{weight};
    }

    my $branding_id = $brandings_list[ int( rand( scalar(@brandings_list) ) ) ];

    my $persistent = $class->get_ad_zone($persistent_id);
    my $branding   = $class->get_ad_zone($branding_id);

# router|$device_id              = { account_id => $a, mac => $m, lan_ip => $l };
# account|$account_id            = { advertise_here => $a, aaa => $b };

    # process the template
    my $account = $class->get_account($account_id);

    #	my $account = SL::Cache->memd->get("account|$account_id");
    my $router;
    if ( defined( $account->{aaa} ) ) {

        # grab the lan ip
        $router = $class->get_router($router_id);
    }

    #my $router  = SL::Cache->memd->get("router|$router_id");
    my $output_ref =
      $class->process_ad_template( $persistent, $branding, $router, $account,
        $ua );

    # return the id, string output ref, and css url
    return (
        $persistent->{ad_zone_id}, $output_ref,
        \$persistent->{css_url},   \$persistent->{js_url},
        \$persistent->{head_html}, $persistent->{ad_size_id}
    );
}

# takes ad_data, returns scalar reference of output
sub process_ad_template {
    my ( $class, $persistent, $branding, $router, $account, $ua ) = @_;

    # check to see if this is a floating horizontal ad zone
    if (
        (
            ( substr( $ua, 13, 6 ) eq 'iPhone' ) or    # iPhone
            ( substr( $ua, 25, 6 ) eq 'MSIE 6' ) or    # IE6
            ( substr( $ua, 25, 6 ) eq 'MSIE 7' )       # IE7
        )
        && (
            ( $persistent->{ad_size_id} == 10 )    # Floating Leaderboard
            or ( $persistent->{ad_size_id} == 12 ) # Floating Footer Leaderboard
        )
      )
    {

        # Poof, now you are a static leaderboard
        foreach my $attr (qw( ad_size_id css_url js_url head_html template )) {

            $persistent->{$attr} = $Leaderboard->{$attr};
        }

    }

    my %tmpl_vars = (
        bug_link_href  => $branding->{link_href},
        bug_image_href => $branding->{image_href},

        zone => $persistent->{ad_zone_id},
        code => $persistent->{code},

        aaa            => $account->{aaa},
        advertise_here => $account->{advertise_here},
        lan_ip         => $router->{lan_ip},
    );

    warn( "tmpl vars: " . Dumper( \%tmpl_vars ) ) if DEBUG;

    # generate the ad
    my $output;
    $Tmpl->process( $persistent->{template}, \%tmpl_vars, \$output )
      || ( warn( $Tmpl->error ) && return );

    return \$output;
}

use constant LOG_VIEW_SQL => q{
-- LOG_VIEW_SQL
INSERT INTO view
( ad_zone_id, router_id, usr_id, url, referer, ip )
values
( ?,
                      (select router_id from router where macaddr = ?),
                                 ?,
                                          ?,   ?,      ? )
};

sub log_view {
    my ( $class, $args_ref ) = @_;

    my $ip  = $args_ref->{ip}  || warn("no ip passed")  && return;
    my $url = $args_ref->{url} || warn("no url passed") && return;
    my $mac = $args_ref->{mac}
      || warn("no mac passed") && return;
    my $user = $args_ref->{user} || warn("no user passed") && return;
    my $ad_zone_id = $args_ref->{ad_zone_id}
      || warn("no ad_zone_id passed") && return;
    my $referer = $args_ref->{referer} || '';

    my $sth = $class->connect->prepare(LOG_VIEW_SQL);

    $sth->bind_param( 1, $ad_zone_id );
    $sth->bind_param( 2, $mac );
    $sth->bind_param( 3, $user );
    $sth->bind_param( 4, $url );
    $sth->bind_param( 5, $referer );
    $sth->bind_param( 6, $ip );

    my $rv;
    unless ( $rv = $sth->execute ) {
        warn(
            sprintf(
"$$ Error, could not log ad_zone_id %d, ip %s, url %s, router %s, user %s",
                $ad_zone_id, $ip, $url, $mac, $user
            )
        );
    }
    $sth->finish;
    return 1 if $rv;
    return;
}

sub swap {
    my ( $class,  $response_ref, $adslots, $router ) = @_;

    die unless $response_ref && $adslots && $router;

    my $plan = $router->{plan};

	#warn("swap for plan $plan");
    foreach my $adslot ( @{$adslots} ) {

        my ( $text, $height, $width ) = @{$adslot}{ qw(ad height width) };

        my $ad;
        if ($plan eq 'free') {
#		warn("adslot width $width, height $height ");

            $ad = $class->grab_sized_default( $height, $width, $router->{account_id} );
        } else {

            $ad = $class->grab_sized_ad( $height, $width, $router->{router_id} );
        }

        if ($ad) {
            my $code = $ad->{code};

            $$response_ref =~
              s/(<\s*?script.*?$$text.*?\/\s*?script\s*?>)/$code/;
        }
    }

    return 1;
}

sub grab_sized_default {

    my ( $class, $height, $width, $account_id ) = @_;

    my $sized = SL::Cache->memd->get("account|$account_id|sized|$height\_$width");

    unless ($sized) {

        $sized = $class->retrieve_account_sized( $height, $width, $account_id );

        return unless $sized;

        # update the cache
        SL::Cache->memd->set(
            "account|$account_id|sized|$height\_$width" => $sized,
            AD_TIMEOUT
        );
    }

    my @sized_list;
    foreach my $sized_unit ( @{$sized} ) {
        push @sized_list, $sized_unit->{ad_zone_id}
          for 1 .. $sized_unit->{weight};
    }

    my $sized_id = $sized_list[ int( rand( scalar(@sized_list) ) ) ];

    my $sized_ad = $class->get_ad_zone($sized_id);

    return $sized_ad;
}

sub grab_sized_ad {

    my ( $class, $height, $width, $router_id ) = @_;

    my $sized = SL::Cache->memd->get("router|$router_id|sized|$height\_$width");

    unless ($sized) {

        $sized = $class->retrieve_router_sized( $height, $width, $router_id );

        return unless $sized;

        # update the cache
        SL::Cache->memd->set(
            "router|$router_id|sized|$height\_$width" => $sized,
            AD_TIMEOUT
        );
    }

    my @sized_list;
    foreach my $sized_unit ( @{$sized} ) {
        push @sized_list, $sized_unit->{ad_zone_id}
          for 1 .. $sized_unit->{weight};
    }

    my $sized_id = $sized_list[ int( rand( scalar(@sized_list) ) ) ];

    my $sized_ad = $class->get_ad_zone($sized_id);

    return $sized_ad;
}

sub retrieve_router_sized {
    my ( $class, $height, $width, $router_id ) = @_;

    my $ad_data = $class->connect->selectall_arrayref(
        <<SQL, { Slice => {} }, $height, $width, $router_id );
SELECT
ad_zone.ad_zone_id,
ad_zone.weight
FROM ad_zone,router__ad_zone, ad_size
WHERE router__ad_zone.router_id = ?
AND ad_zone.active = 't'
AND ad_zone.ad_size_id = ad_size.ad_size_id
AND ad_size.height = ? and ad_size.width = ?
AND router__ad_zone.ad_zone_id = ad_zone.ad_zone_id
SQL

    unless ( $ad_data->[0] ) {
        warn("no sized $width x $height, router $router_id!") if DEBUG;
        return;
    }

    warn( "got router sized " . Dumper($ad_data) ) if DEBUG;

    return $ad_data;
}


sub retrieve_account_sized {
    my ( $class, $height, $width, $account_id ) = @_;

    my $ad_data = $class->connect->selectall_arrayref(
        <<SQL, { Slice => {} }, $height, $width, $account_id );
SELECT
ad_zone.ad_zone_id,
ad_zone.weight
FROM ad_zone, ad_size
WHERE ad_zone.active = 't'
AND ad_zone.ad_size_id = ad_size.ad_size_id
AND ad_size.height = ? and ad_size.width = ?
AND ad_zone.account_id = ?
SQL

    unless ( $ad_data->[0] ) {
        warn("no sized $width x $height, account $account_id!") if DEBUG;
        return;
    }

    warn( "got account sized " . Dumper($ad_data) ) if DEBUG;

    return $ad_data;
}


1;
