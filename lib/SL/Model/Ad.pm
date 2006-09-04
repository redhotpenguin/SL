package SL::Model::Ad;

use strict;
use warnings;

use base 'SL::Model';

=head1 NAME

SL::Ad

=head1 DESCRIPTION

This serves ads, ya see?

=cut

our @ads;

use constant CLICKSERVER_URL    => 'http://h1.redhotpenguin.com:7777/click/';
use constant SILVERLINING_AD_ID => "/795da10ca01f942fd85157d8be9e832e";

our $log_view_sql = <<SQL;
INSERT INTO view
( ad_id, ip ) values ( ?, ? )
SQL

BEGIN {
    refresh_ads();

    sub refresh_ads {
        undef @ads;

        # Load all the ads into a shared global
        my $dbh = SL::Model->db_Main();
        my $sql = <<SQL;
SELECT
ad.ad_id, 
ad.name, 
link.md5, 
link.uri,
ad.template 
FROM ad 
LEFT JOIN link 
USING (ad_id)
WHERE ad.active = 't'
SQL

        my $sth = $dbh->prepare_cached($sql);
        my $rv  = $sth->execute;
        die unless $rv;

        while (my $ad_data = $sth->fetchrow_hashref) {
            require Data::Dumper;
            my $ad = __PACKAGE__->new($ad_data);
            print STDERR "Ad: " . Data::Dumper::Dumper($ad);
            push @ads, $ad;
        }

        $dbh->commit;

        sub new {
            my ($class, $ad_data) = @_;
            my $self = {};
        }
    }
}

=head1 METHODS

=over 4

=item C<container( $css_url, $response, $ad )>

Method for ad insertion which wraps the whole page in a stylesheet

=cut

sub container {
    my ($css_url, $decoded_content, $ad) = @_;

    my $link = qq{<link rel="stylesheet" href="$css_url" type="text/css" />};

    # Insert the stylesheet link
    my $regex = qr{^(.*?)(</\s*head)(.*)$}i;
    $decoded_content =~ s{$regex}{$1$link$2$3}mgs;

    # Insert the rest of the pieces
    my $top       = qq{<div id="sl_top">};
    my $container = qq{</div><div id="sl_ctr">};
    my $tail      = qq{</div>};
    $decoded_content =~ s{^(.*?)<body([^>]*?)>(.*?)</body>(.*)$}
                         {$1<body$2>$top$ad$container$3$tail</body>$4}ismx;

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
    my ($decoded_content, $ad) = @_;
    $decoded_content =~ s{^(.*?)<body([^>]*?)>}{$1<body$2>$ad}isxm;
    return $decoded_content;
}

=item C<_stacked_page($decoded_content, $ad)>

Method for ad insertion which puts the ad in it's own html page and serves that
inline with the original request response.

=cut

sub stacked {
    my ($decoded_content, $ad) = @_;
    my $html = qq{<html><body>$ad</body></html>};
    $decoded_content = join("\n", $html, $decoded_content);
    return $decoded_content;
}

sub random {
    my $class = shift;
    refresh_ads() if $SL::Debug;
    my $index = int(rand(scalar(@ads)));
    return $ads[$index];
}

sub as_html {
    my $self = shift;

    return $self->{'_html'};
}

sub log_view {
	my ($ip, $ad) = @_;



	my $dbh = SL::Model->db_Main();
    my $sth = $dbh->prepare($log_view_sql);
    $sth->bind_param( 1, $ad->{'ad_id'} );
    $sth->bind_param( 2, $ip);
    my $rv = $sth->execute;
	return 1 if $rv;
	return;
}

1;
