package SL::Model::Ad;

use strict;
use warnings;

use base 'SL::Model';

use Template;

=head1 NAME

SL::Ad

=head1 DESCRIPTION

This serves ads, ya see?

=cut

use constant DEFAULT_AD_GROUP_ID => 1;
use constant LOG_VIEW_SQL        => q{
INSERT INTO view
( ad_id, ip ) values ( ?, ? )
};

use constant AD_ID_IDX       => 0;
use constant TEXT_IDX        => 1;
use constant MD5_IDX         => 2;
use constant URI_IDX         => 3;
use constant TEMPLATE_IDX    => 4;
use constant CSS_URL_IDX     => 5;
use constant IMAGE_HREF_IDX  => 6;
use constant LINK_HREF_IDX   => 7;

use SL::Config;
our $CONFIG = SL::Config->new;
our $PATH   = $CONFIG->sl_root . '/tmpl/';
die "Template include path $PATH doesn't exist!\n" unless -d $PATH;
my $TMPL_CONFIG = {
    ABSOLUTE     => 1,
    INCLUDE_PATH => $PATH,
};
our $TEMPLATE = Template->new($TMPL_CONFIG) || die $Template::ERROR, "\n";

=head1 METHODS

=over 4

=item C<container( $css_url, $response, $ad )>

Method for ad insertion which wraps the whole page in a stylesheet

=cut

our( $regex, $second_regex, $uber_match, $end_body_match );
our( $top,   $container,    $tail );

BEGIN {
    $top            = qq{<div id="sl_top">};
    $container      = qq{</div><div id="sl_ctr">};
    $tail           = qq{</div>};
    $regex          = qr{^(.*?<\s*?head\s*?>)(.*)$}is;
    $second_regex   = qr{\G(.*?)<body([^>]*?)>(.*)$}is;
    $uber_match     = qr{\G(?:</\s*?head\s*?>)}i;
    $end_body_match = qr{^(.*)(<\s*?/body\s*?>.*)$}i;
}

sub container {
    my ( $css_url_ref, $decoded_content_ref, $ad_ref ) = @_;

    my $link =
      qq{<link rel="stylesheet" href="$$css_url_ref" type="text/css" />};

    # Insert the stylesheet link
    $$decoded_content_ref =~ s{$regex}{$1$link$2};

    # move the pointer - optimization, 0.5 milliseconds
    $$decoded_content_ref =~ m/$uber_match/;

    # Insert the rest of the pieces
    $$decoded_content_ref =~ s{$second_regex}
                         {$1<body$2>$top$$ad_ref$container$3};

    # insert the tail
    $end_body_match = qr{^(.*)(<\s*?/body\s*?>.*)$}i;
    $$decoded_content_ref =~ s{$end_body_match}{$1$tail$2};

    return $decoded_content_ref;
}

=item C<body_regex> 

Method for ad insertion which puts an html paragraph right after the body tag.

  $page_with_ad = body_regex( $decoded_content, $ad );

=over 4

=item C<$decoded_content> ( string )

The decoded HTTP::Response content.

=item C<$ad> ( string )

The ad content

=back

=cut

sub body_regex {
    my ( $decoded_content, $ad ) = @_;
    $decoded_content =~ s{^(.*?)<body([^>]*?)>}{$1<body$2>$$ad}isxm;
    return $decoded_content;
}

=item C<_stacked_page($decoded_content, $ad)>

Method for ad insertion which puts the ad in the html page and serves that
inline with the original request response.

=cut

sub stacked {
    my ( $decoded_content, $ad ) = @_;
    my $html = qq{<html><body>$$ad</body></html>};
    $decoded_content = join ( "\n", $html, $decoded_content );
    return $decoded_content;
}

use constant SL_FEED_SQL => q{
SELECT
ad_linkshare.ad_id,    ad_linkshare.displaytext AS text,
ad.md5,                ad_linkshare.linkurl AS uri,
ad_group.template,     ad_group.css_url,
bug.image_href,        bug.link_href
FROM ad_linkshare, ad, router, ad__ad_group, router__ad_group, ad_group, bug
WHERE ad.active = 't'
AND ad_linkshare.ad_id = ad.ad_id
AND ad__ad_group.ad_id = ad.ad_id
AND router__ad_group.ad_group_id = ad__ad_group.ad_group_id
AND ad_group.bug_id = bug.bug_id
AND router.ip = ?
ORDER BY RANDOM()
LIMIT 1
};

sub _sl_feed {
    my ( $class, $ip ) = @_;

    # only linkshare for right now
    my $dbh = SL::Model->connect();
    my $sth = $dbh->prepare(SL_FEED_SQL);
    $sth->bind_param( 1, $ip );
    my $rv = $sth->execute;
    die "Problem executing query: " . SL_FEED_SQL unless $rv;

    my $ad_data = $sth->fetchrow_arrayref;
    $sth->finish;
    return $ad_data;
}

use constant RANDOM_ADGROUP_FROM_IP => q{
SELECT ad_group.ad_group_id, css_url, template 
FROM ad_group, location, location__ad_group
WHERE location__ad_group.ad_group_id =  ad_group.ad_group_id
AND location__ad_group.location_id = location.location_id
AND location.ip = ?
ORDER BY RANDOM()
LIMIT 1
};

use constant SL_LOCATION_SQL => q{
SELECT
ad_sl.ad_id,         ad_sl.text,         ad.md5,     ad_sl.uri,
ad_group.template,   ad_group.css_url, 
bug.image_href,      bug.link_href
FROM ad_sl, ad, ad__ad_group, ad_group, bug
WHERE ad.active = 't'
AND ad__ad_group.ad_group_id = ?
AND ad__ad_group.ad_id = ad.ad_id
AND ad_sl.ad_id = ad.ad_id
AND ad_group.bug_id = bug.bug_id
ORDER BY RANDOM()
LIMIT 1
};

sub _sl_location {
    my ( $class, $ip ) = @_;

    die 'no ip' unless $ip;

    my $dbh = SL::Model->connect();

    # are there any location__ad_groups for this location?
    my $random_adgroup_sth = $dbh->prepare_cached(RANDOM_ADGROUP_FROM_IP);
    $random_adgroup_sth->bind_param( 1, $ip );
    $random_adgroup_sth->execute or die $DBI::errstr;

    # grab the ad_group data
    my $ad_group_ary_ref = $random_adgroup_sth->fetchrow_arrayref;
    $random_adgroup_sth->finish;

    # no ad groups?
    return unless $ad_group_ary_ref;

    # grab the ad data
    my $location_sth = $dbh->prepare_cached(SL_LOCATION_SQL);
    $location_sth->bind_param( 1, $ad_group_ary_ref->[0] );
    $location_sth->execute or die $DBI::errstr;

    my $ad_data = $location_sth->fetchrow_arrayref;
    $location_sth->finish;

    # merge in the ad_group data
    $ad_data->[CSS_URL_IDX]  = $ad_group_ary_ref->[1];
    $ad_data->[TEMPLATE_IDX] = $ad_group_ary_ref->[2];
    return $ad_data;
}

use constant SL_ROUTER_SQL => q{
SELECT
ad_sl.ad_id,      ad_sl.text,        ad.md5,
ad_sl.uri,        ad_group.template, ad_group.css_url,
bug.image_href,   bug.link_href
FROM ad_sl, ad, router, ad__ad_group, router__ad_group, ad_group, bug
WHERE ad.active = 't'
AND ad.ad_id = ad_sl.ad_id
AND ad.ad_id = ad__ad_group.ad_id
AND ad__ad_group.ad_group_id = ad_group.ad_group_id
AND ad_group.bug_id = bug.bug_id
AND router__ad_group.ad_group_id = ad_group.ad_group_id
AND (router.router_id = router__ad_group.router_id
AND router.router_id = ? )
ORDER BY RANDOM()
LIMIT 1
};

sub _sl_router {
    my ( $class, $ip ) = @_;

    # grab the routers associated with this location
    my $router_id =
      SL::Model::Proxy::Router::Location->get_router_id_by_ip($ip);
    return unless $router_id;

    # get the ads specific to this router_id
    my $dbh = SL::Model->connect();
    my $sth = $dbh->prepare(SL_ROUTER_SQL);
    $sth->bind_param( 1, $router_id );
    my $rv = $sth->execute;
    die "Problem executing query: " . SL_ROUTER_SQL unless $rv;

    my $ad_data = $sth->fetchrow_arrayref;
    $sth->finish;
    return $ad_data;
}

use constant SL_DEFAULT_SQL => q{
SELECT 
ad_sl.ad_id,       ad_sl.text,        ad.md5,
ad_sl.uri,         ad_group.template, ad_group.css_url,
bug.image_href,    bug.link_href
FROM ad_sl, ad, location, ad__ad_group, ad_group, bug
WHERE ad.active = 't'
AND ad_sl.ad_id = ad.ad_id
AND ad__ad_group.ad_id = ad.ad_id
AND ad_group.bug_id = bug.bug_id
AND ad__ad_group.ad_group_id = ?
AND location.ip = ?
AND location.default_ok = 't'
ORDER BY RANDOM()
LIMIT 1
};

sub _sl_default {
    my ( $class, $ip ) = @_;

    my $dbh = SL::Model->connect();
    my $sth = $dbh->prepare_cached(SL_DEFAULT_SQL);
    $sth->bind_param( 1, DEFAULT_AD_GROUP_ID );
    $sth->bind_param( 2, $ip );
    my $rv = $sth->execute;
    die "Problem executing query: " . SL_DEFAULT_SQL unless $rv;

    my $ad_data = $sth->fetchrow_arrayref;
    $sth->finish;
    return $ad_data;
}

# this method returns a random ad, given the ip of the router
sub random {
    my ( $class, $ip ) = @_;

    # figure out what ad to serve.
    # current logic says  use default/custom ad groups 25% of the time
    # and our feeds 75% of the time
    my $feed_threshold   = 100;
    my $custom_threshold = 0;
    my $ad_data;
    my $rand = rand(100);
    if ( $rand >= $feed_threshold ) {
        $ad_data = $class->_sl_feed($ip);
    }
    elsif ( $rand >= $custom_threshold ) {

        # grab an ad for this location
        $ad_data = $class->_sl_location($ip);

        unless ( defined $ad_data->[TEXT_IDX] ) {

            # nothing for location, try router specific
            $ad_data = $class->_sl_router($ip);
        }
    }

    # no ad returned?
    unless ( defined $ad_data->[TEXT_IDX] ) {
        $ad_data = $class->_sl_default($ip);

        # going to hell for this one
        return unless defined $ad_data->[TEXT_IDX];
    }
    
    my %tmpl_vars = (
        ad_link    => $CONFIG->sl_clickserver_url . $ad_data->[MD5_IDX],
        ad_text    => $ad_data->[TEXT_IDX],
        image_href => $ad_data->[IMAGE_HREF_IDX],
        link_href  => $ad_data->[LINK_HREF_IDX],
    );

    # generate the ad
    my $output;
    $TEMPLATE->process( $ad_data->[TEMPLATE_IDX], \%tmpl_vars, \$output )
      || die $TEMPLATE->error();

    # return the id, string output, and css url
    return ( $ad_data->[AD_ID_IDX], \$output, \$ad_data->[CSS_URL_IDX], );
}

sub log_view {
    my ( $class, $ip, $ad_id ) = @_;

    my $dbh = SL::Model->db_Main();
    my $sth = $dbh->prepare(LOG_VIEW_SQL);
    $sth->bind_param( 1, $ad_id );
    $sth->bind_param( 2, $ip );
    my $rv = $sth->execute;
    $sth->finish;
    return 1 if $rv;
    return;
}

1;
