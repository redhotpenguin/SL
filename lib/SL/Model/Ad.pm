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

use constant CLICKSERVER_URL    => 'http://h1.redhotpenguin.com:7777/click/';
use constant SILVERLINING_AD_ID => "/795da10ca01f942fd85157d8be9e832e";

my $template;
our( $log_view_sql, %sl_ad_data );

BEGIN {

    $log_view_sql = <<SQL;
INSERT INTO view
( ad_id, ip ) values ( ?, ? )
SQL
    my $tmpl_config = {
        ABSOLUTE     => 1,
        INCLUDE_PATH => $ENV{SL_ROOT} . "/tmpl/"
    };
    $template = Template->new($tmpl_config) || die $Template::ERROR, "\n";
    %sl_ad_data = ( sl_link => CLICKSERVER_URL . SILVERLINING_AD_ID );

}

=head1 METHODS

=over 4

=item C<container( $css_url, $response, $ad )>

Method for ad insertion which wraps the whole page in a stylesheet

=cut

sub container {
    my ( $css_url, $decoded_content, $ad ) = @_;

    my $link = qq{<link rel="stylesheet" href="$css_url" type="text/css" />};

    # Insert the stylesheet link
    my $regex = qr{^(.*?)(</\s*head)(.*)$}i;
    $decoded_content =~ s{$regex}{$1$link$2$3}mgs;

    # Insert the rest of the pieces
    my $top       = qq{<div id="sl_top">};
    my $container = qq{</div><div id="sl_ctr">};
    my $tail      = qq{</div>};
    $decoded_content =~ s{^(.*?)<body([^>]*?)>(.*?)</body>(.*)$}
                         {$1<body$2>$top$$ad$container$3$tail</body>$4}ismx;

    return $decoded_content;
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

Method for ad insertion which puts the ad in it's own html page and serves that
inline with the original request response.

=cut

sub stacked {
    my ( $decoded_content, $ad ) = @_;
    my $html = qq{<html><body>$$ad</body></html>};
    $decoded_content = join ( "\n", $html, $decoded_content );
    return $decoded_content;
}

sub _sl_feed {
    my ($class, $ip) = @_;
    
    # only linkshare for right now
    my $sql = <<SQL;
SELECT
ad_linkshare.ad_id,
ad_linkshare.displaytext AS text,
ad.md5,
ad_linkshare.linkurl AS uri
FROM ad_linkshare
INNER JOIN ad USING(ad_id)
WHERE ad.active = 't'
ORDER BY RANDOM()
LIMIT 1
SQL

    my $dbh = SL::Model->connect();
    my $sth = $dbh->prepare($sql);
    my $rv = $sth->execute;
    die "Problem executing query: $sql" unless $rv;

    my $ad_data = $sth->fetchrow_hashref;
    $sth->finish;
    $ad_data->{'template'} = 'text_ad';
    return $ad_data;
}

sub _sl_ad {
    my ($class, $ip) = @_;

    my $ad_groups_ref = SL::Model::Ad::Group->from_ip($ip);
    my $ad_group_count = scalar(@{$ad_groups_ref});
    my $in = '?,' x $ad_group_count;

    # remove the trailing ','
    {
      no warnings;
      substr($in, -length($in), length($in)-1);
    }

    my $sql = <<SQL;
SELECT
ad_sl.ad_id, 
ad_sl.text,
ad.md5, 
ad_sl.uri
FROM ad_sl
INNER JOIN ad USING (ad_id)
INNER JOIN ad_group USING (ad_sl_group_id)
WHERE ad.active = 't'
AND ad_group_id = ($in)
ORDER BY RANDOM()
LIMIT 1
SQL
    my $dbh = SL::Model->connect();
    my $sth = $dbh->prepare($sql);
    my $i = 1;
    $sth->bind_param($i++, $_->ad_group_id) for @{$ad_groups_ref};
	my $rv = $sth->execute;
    die "Problem executing query: $sql" unless $rv;

    my $ad_data = $sth->fetchrow_hashref;
    $sth->finish;
    $ad_data->{'template'} = 'text_ad';
    return $ad_data;
}

# this method returns a random ad, given the ip of the router
sub random {
    my ( $class, $ip ) = @_;

    # figure out what ad to serve.
    # current logic says  use default/custom ad groups 25% of the time
    # and our feeds 75% of the time
    my $custom_ad_weight = 25;
    my $ad_data;
    if (rand(100) <= $custom_ad_weight) {
        $ad_data = $class->_sl_ad($ip);
    } else {
        $ad_data = $class->_sl_feed($ip);
    }
 
	my %tmpl_vars;
    # ad setup based on ad type here
    if ( $ad_data->{'template'} eq 'javascript' ) {
        $tmpl_vars{'ad_link'} = $ad_data->{'uri'};
    }
    else {
        $tmpl_vars{'ad_link'} = CLICKSERVER_URL . $ad_data->{'md5'};
        $tmpl_vars{'ad_text'} = $ad_data->{'text'};
    }

	my $output;
    $template->process( $ad_data->{'template'} . '.tmpl',
        {%tmpl_vars, %sl_ad_data}, \$output )
      || die $template->error(), "\n";

	return ($ad_data->{'ad_id'}, \$output);
}

sub log_view {
    my ( $class, $ip, $ad_id ) = @_;

	print STDERR "Logging view for ip $ip, ad_id $ad_id\n";
    my $dbh = SL::Model->db_Main();
    my $sth = $dbh->prepare($log_view_sql);
    $sth->bind_param( 1, $ad_id);
    $sth->bind_param( 2, $ip );
    my $rv = $sth->execute;
    $sth->finish;
    return 1 if $rv;
    return;
}

1;
