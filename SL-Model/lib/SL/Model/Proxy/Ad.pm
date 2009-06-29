package SL::Model::Proxy::Ad;

use strict;
use warnings;

use base 'SL::Model';

use Template                 ();
use SL::Config               ();
use SL::Cache                ();

=head1 NAME

SL::Model::Ad

=head1 DESCRIPTION

This serves ads, ya see?

=cut

use constant AD_ZONE_ID        => 0;
use constant AD_ZONE_CODE      => 1;
use constant AD_ZONE_WEIGHT    => 2;
use constant AD_ZONE_DEFAULT   => 3;
use constant AD_ZONE_AD_SIZE   => 4;

use constant DEBUG => $ENV{SL_DEBUG} || 0;

our ($Config, $Tmpl,$Leaderboard);

# memcached data structure mapping
# thou shalt not change schema without thinking first
# else I will hit you with a stick ;)
#
# router|$device_id|brandings      = $branding_zone_id;
# router|$device_id|splashes       = [ $splash_zone_id => $weight1, ];
# router|$device_id|persistents    = [ $persistent_zone_id_1 => $zone1_weight, .. ];
# router|$device_id                = { account_id => $a, mac => $m, lan_ip => $l };
# router|$device_mac               = $device_id;
#
# adzone|$zone_id                = $zone_content;
#
# adzone|default_persistents            = $zone_id;
# adzone|default_splashes          = $zone_id;
# adzone|default_brandings        = $zone_id;
#
# adzone|$account_id|default_persistents     = [ $zone_id, $zone_id2, ];
# adzone|$account_id|default_splashes   = [ $zone_id, $zone_id2, ];
# adzone|$account_id|default_brandings = [ $zone_id, $zone_id2, ];
#
#
# account|$account_id            = { advertise_here => $a, aaa => $b, marketplace => $m };
#
# location|$ip                   = [ { 'FF:FF:FF:FF:FF:FF' => '2001-06-01 00:00:00' },
#                                    { $device2_mac => .. }, ];

BEGIN {
    $Config = SL::Config->new;

    my $path = $Config->sl_root . '/tmpl/';
    die "Template include path $path doesn't exist!\n" unless -d $path;

    my $tmpl_config = { ABSOLUTE => 1, INCLUDE_PATH => $path, };
    $Tmpl = Template->new($tmpl_config) || die $Template::ERROR,;

    $Leaderboard = SL::Model->connect->selectrow_hashref(<<SQL,{} , 1);
SELECT ad_size_id,css_url,js_url,head_html,template
FROM ad_size WHERE ad_size_id = ?
SQL

    die "no leaderboard size" unless $Leaderboard;

    require Data::Dumper if DEBUG;
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
    $tail = qq{</div>};

    $head_regex = qr{^(.*?<\s*?head\s*?[^>]*?>)(.*)$}is;    # start of head
    #$head_regex          = qr{^(.*)(<\s*?\/head\s*?>.*)$}is;  # end of head
    $uber_match       = qr{\G(?:</\s*?head\s*?>)}i;
    $start_body_regex = qr{\G(.*?)<body([^>]*?)>(.*)$}is;
    $end_body_match   = qr{^(.*)(<\s*?/body\s*?>.*)$}is;
    $html_regex       = qr{^(.*?<\s*?html[^>]*?>)(.*)$}is;
}

our $HEAD = <<HEAD;
<link rel="stylesheet" type="text/css" href="%s" />%s
HEAD

our $JS = <<JS;
<script type="text/javascript" src="%s"></script>
JS

sub container {
    my ( $css_url_ref, $js_url_ref, $head_html_ref, $decoded_content_ref, $ad_ref ) = @_;

    # check to make sure that we can insert all parts of the ad
    return
      unless ( ( $$decoded_content_ref =~ m/$head_regex/ )
        && ( $$decoded_content_ref =~ m/$start_body_regex/ ) );

    if ( !defined $$head_html_ref ) {
        $$head_html_ref = '';
    }

    # build the head content
    my $head = sprintf( "$HEAD", $$css_url_ref, $$head_html_ref );

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
    my $js = sprintf( "$JS", $$js_url_ref );
    $matched = $$decoded_content_ref =~ s{$end_body_match}{$1$tail$js$2};
    warn('failed to insert closing div') unless ( DEBUG && $matched );

    return 1;
}




# grabs the default persistents for an account
sub retrieve_account_default_persistents {
    my ( $class, $account_id ) = @_;

    my $ad_data = $class->connect->selectall_arrayref(<<SQL, { Slice => {}}, $account_id);
SELECT
ad_zone.ad_zone_id,
ad_zone.weight
FROM ad_zone,ad_size
WHERE ad_zone.account_id = ?
AND ad_zone.is_default = 't'
AND ad_zone.active = 't'
AND ad_zone.ad_size_id = ad_size.ad_size_id
AND ad_size.grouping = 1
SQL

    return unless $ad_data;
    return $ad_data;
}

# grabs the default brandings for an account
sub retrieve_account_default_brandings {
    my ( $class, $account_id ) = @_;

    my $ad_data = $class->connect->selectall_hashref(<<SQL, {}, $account_id);
SELECT
ad_zone.ad_zone_id,
ad_zone.weight
FROM ad_zone,ad_size
WHERE ad_zone.account_id = ?
AND ad_zone.is_default = 't'
AND ad_zone.active = 't'
AND ad_zone.ad_size_id = ad_size.ad_size_id
AND ad_size.grouping = 2
SQL

    return unless $ad_data;
    return $ad_data;
}


# returns the ad ids of the account zones
sub account_default_zones {
    my ( $class, $account_id ) = @_;

    my $persistents = $class->account_default_persistents( $account_id ) || return;

    my $brandings = $class->account_default_brandings( $account_id ) || return;

    return ($persistents, $brandings);
}

sub account_default_persistents {
    my ($class, $account_id) = @_;

    # check memcached for account default persistents
    # adzone|$account_id|default_persistents = [ $persistent_zone_id_1 => $zone1_weight, .. ];
    my $persistents = SL::Cache->memd->get("adzone|$account_id|default_persistents");

    unless ($persistents) {

        # go to the database
        $persistents = $class->retrieve_account_default_persistents( $account_id );

        unless ($persistents) {
            warn("no default persistents for account $account_id") if DEBUG;
            return;
        }

        # update the cache
        $persistents = [ map { $_->[0] => $_->[1] } @{$persistents} ];
        SL::Cache->memd->set("adzone|$account_id|default_persistents") = $persistents;
    }

    return $persistents;
}


# returns the ad ids of the account default branding zones
sub account_default_brandings {
    my ($class, $account_id) = @_;

    # grab the default branding images
    # adzone|$account_id|default_branding = [ $persistent_zone_id_1 => $zone1_weight, .. ];
    my $brandings = SL::Cache->memd->get("adzone|$account_id|default_brandings");

    unless ($brandings) {

        # go to the database
        $brandings = $class->retrieve_account_default_brandings( $account_id );

        unless ($brandings) {

            warn("no default brandings for account $account_id") if DEBUG;
            return;
        }

        # update the cache
        $brandings = [ map { $_->[0] => $_->[1] } @{$brandings} ];
        SL::Cache->memd->set("adzone|$account_id|default_brandings") = $brandings;
    }

    return $brandings;
}





sub retrieve_router_persistents {
    my ( $class, $router_id ) = @_;

    my $ad_data = $class->connect->selectall_arrayref(<<SQL, {Slice => {}}, $router_id);
SELECT
ad_zone.ad_zone_id,
ad_zone.weight
FROM ad_zone,router,ad_size,router__ad_zone
WHERE router.router_id = ?
AND ad_zone.active = 't'
AND ad_size.grouping = 1
AND ad_zone.ad_size_id = ad_size.ad_size_id
AND router__ad_zone.ad_zone_id = ad_zone.ad_zone_id
AND router__ad_zone.router_id = router.router_id
SQL

    return unless $ad_data;
    return $ad_data;
}


sub retrieve_router_brandings {
    my ( $class, $router_id ) = @_;

    my $ad_data = $class->connect->selectall_arrayref(<<SQL, {Slice => {}}, $router_id);
SELECT
ad_zone.ad_zone_id,
ad_zone.weight
FROM ad_zone,router,router__ad_zone,ad_size
WHERE router.router_id = ?
AND ad_zone.active = 't'
AND ad_size.grouping = 2
AND ad_zone.ad_zone_id = ad_size.ad_size_id
AND router__ad_zone.ad_zone_id = ad_zone.ad_zone_id
AND router__ad_zone.router_id = router.router_id
SQL

    return unless $ad_data;
    return $ad_data;
}





sub router_ad_zones {
    my ( $class, $router_id, $account_id ) = @_;

    my $persistents = $class->router_persistents( $router_id, $account_id ) || return;

    my $brandings = $class->router_brandings( $router_id, $account_id ) || return;

    return ($persistents, $brandings);
}


sub router_persistents {
    my ($class, $router_id, $account_id) = @_;

    my $persistents = SL::Cache->memd->get("router|$router_id|persistents");
    unless ($persistents) {

        $persistents = $class->retrieve_router_persistents( $router_id );

        unless ($persistents) {
            warn("no persistents for router $router_id") if DEBUG;
            return;
        }

        # update the cache
        SL::Cache->memd->set("adzone|$router_id|persistents" => $persistents);
    }

    return $persistents;
}

sub router_brandings {
    my ($class, $router_id, $account_id) = @_;

    my $brandings = SL::Cache->memd->get("router|$router_id|brandings");
    unless ($brandings) {

        $brandings = $class->retrieve_router_brandings( $router_id );

        unless ($brandings) {
            warn("no brandings for router $router_id") if DEBUG;
            return;
        }

        # update the cache
        SL::Cache->memd->set("adzone|$router_id|brandings" => $brandings);
    }

    return $brandings;
}




sub get_ad_zone {
    my ($class, $ad_zone_id) = @_;

    # check the cache for the ad zone
    my $ad_data = SL::Cache->memd->get("ad_zone|$ad_zone_id");

    unless ($ad_data) {
        # grab it from the database
        $ad_data = $class->retrieve_ad_zone( $ad_zone_id );
        die "missing ad zone $ad_zone_id" unless $ad_data;

        SL::Cache->memd->set("ad_zone|$ad_zone_id" => $ad_data);
    }

    return $ad_data;
}




sub retrieve_ad_zone {
    my ($class, $ad_zone_id) = @_;

    my $ad_data = $class->connect->selectrow_hashref(<<SQL, {}, $ad_zone_id);
SELECT
ad_zone.ad_zone_id,
ad_zone.weight,
ad_zone.code,
ad_zone.image_href,
ad_zone.link_href,
ad_zone.ad_size_id,
ad_size.head_html,
ad_size.js_url,
ad_size.css_url
FROM ad_zone,ad_size
WHERE ad_zone.ad_zone_id = ?
AND ad_size.ad_size_id = ad_zone.ad_size_id
SQL

    return unless $ad_data;
    return $ad_data;
}






# silverlining ad dispatcher
# this method returns a random ad, given the id of the router

sub random {
    my ( $class, $args ) = @_;

    my $url         = $args->{url}        || warn("no url passed")        && return;
    my $router_id   = $args->{router_id}  || warn("no router_id passed")  && return;
    my $user        = $args->{user}       || warn("no user passed")       && return;
    my $ua          = $args->{ua}         || warn("no ua passed")         && return;


    my $device = SL::Cache->memd->get("router|$router_id");

    my $account_id = $device->{account_id};

    my $device_guess = $args->{device_guess};

    my ($persistents, $brandings);
    if ($device_guess) {

        # grab ad ids based on the ip
        ($persistents, $brandings) = $class->account_default_ad_zones( $account_id );

    } else {

        # grab the ads specific to this device
        ($persistents, $brandings) = $class->router_ad_zones( $router_id, $account_id );
    }

    unless (@{$persistents} && @{$brandings}) {

        warn("no ads for router $router_id, account $account_id") if DEBUG;
        return;
    }


    # grab a weighted random ad
    my @persistents_list;
    foreach my $ad_zone ( @{$persistents} ) {
        push @persistents_list, $ad_zone->{ad_zone_id} for 1..$ad_zone->{weight};
    }

    my $persistent_id = $persistents_list[int(rand(scalar(@persistents_list)))];


    my @brandings_list;
    foreach my $ad_zone ( @{$brandings} ) {
        push @brandings_list, $ad_zone->{ad_zone_id} for 1..$brandings->{weight};
    }

    my $branding_id = $brandings_list[int(rand(scalar(@brandings_list)))];

    my $persistent = $class->get_ad_zone( $persistent_id );
    my $branding   = $class->get_ad_zone( $branding_id );

    # router|$device_id              = { account_id => $a, mac => $m, lan_ip => $l };
    # account|$account_id            = { advertise_here => $a, aaa => $b };

    # process the template
    my $account = SL::Cache->memd->get("account|$account_id");
    my $router  = SL::Cache->memd->get("router|$router_id");
    my $output_ref = $class->process_ad_template($persistent, $branding, $router, $account, $ua);

    # return the id, string output ref, and css url
    return (
        $persistent->{ad_zone_id},
        $output_ref,
        \$persistent->{css_url},
        \$persistent->{js_url},
        \$persistent->{head_html},
        $persistent->{ad_size_id}
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
        &&
        (
               ( $persistent->{ad_size_id} == 10 ) # Floating Leaderboard
            or ( $persistent->{ad_size_id} == 12 ) # Floating Footer Leaderboard
        )
      )
    {

        # Poof, now you are a static leaderboard
        foreach my $attr ( qw( ad_size_id css_url js_url head_html template ) ) {

            $persistent->{$attr} = $Leaderboard->{$attr};
        }

    }


    my %tmpl_vars = (
        bug_link_href  => $branding->{link_href},
        bug_image_href => $branding->{image_href},

        zone           => $persistent->{ad_zone_id},
        code           => $persistent->{code},

        lan_ip         => $router->{lan_ip},

        advertise_here => $account->{advertise_here},
        aaa            => $account->{aaa},
    );

    warn( "tmpl vars: " . Data::Dumper::Dumper( \%tmpl_vars ) ) if DEBUG;

    # generate the ad
    my $output;
    $Tmpl->process( $persistent->{template}, \%tmpl_vars, \$output )
      || (warn("template error") && return);

    return \$output;
}








use constant LOG_VIEW_SQL => q{
-- LOG_VIEW_SQL
INSERT INTO view
( ad_zone_id, location_id, router_id, usr_id, url, referer, ip )
values
( ?,     (select location_id from location where ip = ?),
                      (select router_id from router where macaddr = ?),
                                 ?,
                                          ?,   ?,      ? )
};

sub log_view {
    my ( $class, $args_ref ) = @_;

    my $ip = $args_ref->{ip}  || warn("no ip passed")  && return;
    my $url = $args_ref->{url} || warn("no url passed") && return;
    my $mac = $args_ref->{mac}
      || warn("no mac passed") && return;
    my $user = $args_ref->{user} || warn("no user passed") && return;
    my $ad_zone_id = $args_ref->{ad_zone_id}
      || warn("no ad_zone_id passed") && return;
    my $referer = $args_ref->{referer} || '';

    my $sth = $class->connect->prepare(LOG_VIEW_SQL);

    $sth->bind_param( 1, $ad_zone_id );
    $sth->bind_param( 2, $ip );
    $sth->bind_param( 3, $mac );
    $sth->bind_param( 4, $user );
    $sth->bind_param( 5, $url );
    $sth->bind_param( 6, $referer );
    $sth->bind_param( 7, $ip );

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

1;