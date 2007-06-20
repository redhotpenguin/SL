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

use constant CLICKSERVER_URL    => 'http://64.151.90.20:81/click/';
use constant SILVERLINING_AD_ID => "/795da10ca01f942fd85157d8be9e832e";
use constant DEFAULT_BUG_LINK =>
  'http://www.redhotpenguin.com/images/sl/free_wireless.gif';

use constant OCC_IP      => '198.145.32.11';
use constant SL_CSS_URL  => 'http://www.redhotpenguin.com/css/sl.css';
use constant OCC_CSS_URL => 'http://www.redhotpenguin.com/css/occ.css';

use constant DEFAULT_AD_GROUP_ID => 1;

my ( $template, $config );
our ( $log_view_sql, %sl_ad_data );

BEGIN {
    require SL::Config;
    $config = SL::Config->new;

    $log_view_sql = <<SQL;
INSERT INTO view
( ad_id, ip ) values ( ?, ? )
SQL

    my $path = $config->sl_root . '/tmpl/';
    die "Template include path $path doesn't exist!\n" unless -d $path;
    my $tmpl_config = {
        ABSOLUTE     => 1,
        INCLUDE_PATH => $config->sl_root . '/tmpl/',
    };
    $template = Template->new($tmpl_config) || die $Template::ERROR, "\n";
    %sl_ad_data = ( sl_link => CLICKSERVER_URL . SILVERLINING_AD_ID );

}

=head1 METHODS

=over 4

=item C<container( $css_url, $response, $ad )>

Method for ad insertion which wraps the whole page in a stylesheet

=cut

our ( $regex, $second_regex, $uber_match, $end_body_match );
our ( $top, $container, $tail );

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
    $decoded_content = join( "\n", $html, $decoded_content );
    return $decoded_content;
}

sub _sl_feed {
    my ( $class, $ip ) = @_;

    # only linkshare for right now
    my $sql = <<SQL;
SELECT
ad_linkshare.ad_id,
ad_linkshare.displaytext AS text,
ad.md5,
ad_linkshare.linkurl AS uri
FROM ad_linkshare, ad, router, ad__ad_group, router__ad_group
WHERE ad.active = 't'
AND ad_linkshare.ad_id = ad.ad_id
AND ad__ad_group.ad_id = ad.ad_id
AND router__ad_group.ad_group_id = ad__ad_group.ad_group_id
AND router.ip = ?
ORDER BY RANDOM()
LIMIT 1
SQL

    my $dbh = SL::Model->connect();
    my $sth = $dbh->prepare($sql);
    $sth->bind_param( 1, $ip );
    my $rv = $sth->execute;
    die "Problem executing query: $sql" unless $rv;

    my $ad_data = $sth->fetchrow_hashref;
    $sth->finish;
    $ad_data->{'template'} = 'text_ad';
    return $ad_data;
}

sub _sl_ad {
    my ( $class, $ip ) = @_;

    my $sql = <<SQL;
SELECT
ad_sl.ad_id,
ad_sl.text,
ad.md5,
ad_sl.uri
FROM ad_sl, ad, router, ad__ad_group, router__ad_group
WHERE ad.active = 't'
AND ad_sl.ad_id = ad.ad_id
AND ad__ad_group.ad_id = ad.ad_id
AND router__ad_group.ad_group_id = ad__ad_group.ad_group_id
AND router.router_id = router__ad_group.router_id
AND router.ip = ?
ORDER BY RANDOM()
LIMIT 1
SQL

    my $dbh = SL::Model->connect();
    my $sth = $dbh->prepare($sql);
    $sth->bind_param( 1, $ip );
    my $rv = $sth->execute;
    die "Problem executing query: $sql" unless $rv;

    my $ad_data = $sth->fetchrow_hashref;
    $sth->finish;
    $ad_data->{'template'} = 'text_ad';
    return $ad_data;
}

sub _sl_default {
    my ( $class, $ip ) = @_;

    my $sql = <<SQL;
SELECT
ad_sl.ad_id,
ad_sl.text,
ad.md5,
ad_sl.uri
FROM ad_sl, ad, router, ad__ad_group, router__ad_group
WHERE ad.active = 't'
AND ad_sl.ad_id = ad.ad_id
AND ad__ad_group.ad_id = ad.ad_id
AND ad__ad_group.ad_group_id = ?
AND router.ip = ?
AND router.default_ok = 't'
ORDER BY RANDOM()
LIMIT 1
SQL

    my $dbh = SL::Model->connect();
    my $sth = $dbh->prepare($sql);
    $sth->bind_param( 1, DEFAULT_AD_GROUP_ID );
    $sth->bind_param( 2, $ip );
    my $rv = $sth->execute;
    die "Problem executing query: $sql" unless $rv;

    my $ad_data = $sth->fetchrow_hashref;
    $sth->finish;
    $ad_data->{'template'} = 'text_ad';
    return $ad_data;
}

sub _bug_link {
    my ( $class, $ip ) = @_;

    return DEFAULT_BUG_LINK;

    my $sql = <<SQL;
SELECT reg_id FROM router WHERE router.ip = ?
SQL
    my $dbh = SL::Model->connect();
    my $sth = $dbh->prepare($sql);
    $sth->bind_param( 1, $ip );
    my $rv = $sth->execute;
    die "Problem executing query: $sql" unless $rv;
    my $ary_ref = $sth->fetchrow_arrayref;
    return DEFAULT_BUG_LINK unless $ary_ref;    # unregistered router

    my $reg_id = $ary_ref->[0];
    if ( -e join( '/', $config->sl_data_root, $reg_id, $ip, 'img/logo.gif' ) ) {
        my $link = join( '/',
            $config->get('sl_app_static_host'),
            'images/sl/user', $reg_id, $ip, 'logo.gif' );
        return $link;
    }

    return DEFAULT_BUG_LINK;
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
        $ad_data = $class->_sl_ad($ip);
    }

    unless ( exists $ad_data->{'text'} ) {
        $ad_data = $class->_sl_default($ip);
        return unless exists $ad_data->{'text'};    # going to hell for this one
    }

    my %tmpl_vars = (
        ad_link  => CLICKSERVER_URL . $ad_data->{'md5'},
        ad_text  => $ad_data->{'text'},
        bug_link => $class->_bug_link($ip)
    );

    my $output;

    # OCC
    if ( $ip eq OCC_IP ) {
        $template->process( 'occ.tmpl', { %tmpl_vars, %sl_ad_data }, \$output )
          || die $template->error(), "\n";
        return ( $ad_data->{'ad_id'}, \$output, OCC_CSS_URL );
    }

    # everybody else
    $template->process( $ad_data->{'template'} . '.tmpl',
        { %tmpl_vars, %sl_ad_data }, \$output )
      || die $template->error(), "\n";

    return ( $ad_data->{'ad_id'}, \$output, SL_CSS_URL );
}

sub log_view {
    my ( $class, $ip, $ad_id ) = @_;

    my $dbh = SL::Model->db_Main();
    my $sth = $dbh->prepare($log_view_sql);
    $sth->bind_param( 1, $ad_id );
    $sth->bind_param( 2, $ip );
    my $rv = $sth->execute;
    $sth->finish;
    return 1 if $rv;
    return;
}

1;
