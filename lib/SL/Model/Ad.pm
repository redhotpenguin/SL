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
use constant DEFAULT_BUG_LINK   => 
  'http://www.redhotpenguin.com/images/sl/free_wireless.gif';
use constant DEFAULT_REG_ID => 14;
use constant  LINKTOADS_IP => '24.7.60.203';
use constant LINKTOADS_AD_ID => 107;

my ($template, $config);
our( $log_view_sql, %sl_ad_data );

BEGIN {
  require SL::Config;
  $config = SL::Config->new;

    $log_view_sql = <<SQL;
INSERT INTO view
( ad_id, ip ) values ( ?, ? )
SQL
    my $tmpl_config = {
        ABSOLUTE     => 1,
        INCLUDE_PATH =>  "/home/phred/dev/sl/trunk/tmpl/"
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

# choose from our selection of default ads
sub _sl_default {
    my $class = shift;

    my $sql = <<SQL;
SELECT 
ad_sl.ad_id, 
ad_sl.text,
ad.md5, 
ad_sl.uri
FROM ad_sl
INNER JOIN ad USING (ad_id)
WHERE ad.active = 't'
AND ad_sl.reg_id = ?
ORDER BY RANDOM()
LIMIT 1
SQL

    my $dbh = SL::Model->connect();
    my $sth = $dbh->prepare($sql);
    $sth->bind_param(1, DEFAULT_REG_ID);
    my $rv = $sth->execute;
    die "Problem executing query: $sql" unless $rv;

    my $ad_data = $sth->fetchrow_hashref;
    $sth->finish;
    $ad_data->{'template'} = 'text_ad';
    return $ad_data;
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

    my $sql = <<SQL;
SELECT
ad_sl.ad_id, 
ad_sl.text,
ad.md5, 
ad_sl.uri
FROM ad_sl
INNER JOIN ad USING (ad_id)
INNER JOIN reg USING (reg_id)
INNER JOIN router USING (reg_id)                                                
WHERE ad.active = 't'
AND router.ip = ?
ORDER BY RANDOM()
LIMIT 1
SQL

    my $dbh = SL::Model->connect();
    my $sth = $dbh->prepare($sql);
    $sth->bind_param(1, $ip);
	my $rv = $sth->execute;
    die "Problem executing query: $sql" unless $rv;

    my $ad_data = $sth->fetchrow_hashref;
    $sth->finish;
    $ad_data->{'template'} = 'text_ad';
    return $ad_data;
}

sub _bug_link {
  my ($class, $ip) = @_;

  my $sql = <<SQL;
SELECT reg_id FROM router WHERE router.ip = ?
SQL
    my $dbh = SL::Model->connect();
    my $sth = $dbh->prepare($sql);
    $sth->bind_param(1, $ip);
	my $rv = $sth->execute;
    die "Problem executing query: $sql" unless $rv;
    my $ary_ref = $sth->fetchrow_arrayref;
    return DEFAULT_BUG_LINK unless $ary_ref; # unregistered router
    
    my $reg_id = $ary_ref->[0];
    if (-e join('/', $config->sl_data_root, $reg_id, $ip, 'img/logo.gif')) {
      my $link = join('/', $config->get('sl_app_static_host'),
		  'images/sl/user', $reg_id, $ip, 'logo.gif');
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
    my $feed_threshold = 50;
    my $custom_threshold = 25;
    my $ad_data;
    my $rand = rand(100);
	if ($rand >= $feed_threshold) {
		$ad_data = $class->_sl_feed($ip);
		   } elsif ( $rand >= $custom_threshold ) {
        $ad_data = $class->_sl_ad($ip);
		 }

    unless (exists $ad_data->{'text'}) {
      $ad_data = $class->_sl_default();
    }

 	my %tmpl_vars = ( 
        ad_link  => CLICKSERVER_URL . $ad_data->{'md5'},
        ad_text  => $ad_data->{'text'},
        bug_link => $class->_bug_link($ip)  );

	my $output;
    
	if ($ip eq LINKTOADS_IP) {
		$template->process( 'linktoads.tmpl',
        {%tmpl_vars, %sl_ad_data}, \$output )
      || die $template->error(), "\n";
		return (LINKTOADS_AD_ID, \$output);
    } else {
		$template->process( $ad_data->{'template'} . '.tmpl',
        {%tmpl_vars, %sl_ad_data}, \$output )
      || die $template->error(), "\n";

	return ($ad_data->{'ad_id'}, \$output);
	}
}

sub log_view {
    my ( $class, $ip, $ad_id ) = @_;

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
