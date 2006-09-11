package SL::Model::Ad;

use strict;
use warnings;

use base 'SL::Model';

use Cache::FastMmap;

our $cache;
BEGIN {
	$cache = Cache::FastMmap->new(share_file => '/tmp/sl_ad_cache');
}

=head1 NAME

SL::Ad

=head1 DESCRIPTION

This serves ads, ya see?

=cut

use constant CLICKSERVER_URL    => 'http://h1.redhotpenguin.com:7777/click/';
use constant SILVERLINING_AD_ID => "/795da10ca01f942fd85157d8be9e832e";

our $log_view_sql = <<SQL;
INSERT INTO view
( ad_id, ip ) values ( ?, ? )
SQL

BEGIN {
    refresh_ads();

    sub refresh_ads {

        # Load all the ads into a shared global
        my $dbh = SL::Model->connect;
        my $sql = <<SQL;
SELECT
ad.ad_id, 
ad.name AS ad_name,
link.md5, 
link.uri,
ad.template, 
ad_group.name AS ad_group_name
FROM ad 
INNER JOIN link 
USING (ad_id)
INNER JOIN ad_group
USING (ad_group_id)
WHERE ad.active = 't'
SQL

        my $sth = $dbh->prepare($sql);
        my $rv  = $sth->execute;
        die unless $rv;

		my %ad_groups;
        while (my $ad_data = $sth->fetchrow_hashref) {
            require Data::Dumper;
            my $ad = __PACKAGE__->new($ad_data);
            print STDERR "Ad: " . Data::Dumper::Dumper($ad);
            push  @{$ad_groups{$ad->{group_name}}}, $ad;
        }
		$sth->finish;
        $dbh->commit;
		
		# cache the ad_groups
		foreach my $ad_group ( keys %ad_groups) {
			$cache->set($ad_group => $ad_groups{$ad_group});
		}

        sub new {
            my ($class, $ad_data) = @_;
            my $self = {};

            require Template;
            my $tmpl_config = {
                               ABSOLUTE     => 1,
                               INCLUDE_PATH => $ENV{SL_ROOT} . "/tmpl/"
                              };
            my $template = Template->new($tmpl_config) || die $Template::ERROR,
              "\n";
            my %tmpl_vars = (sl_link => CLICKSERVER_URL . SILVERLINING_AD_ID);

            # ad setup based on ad type here
            if ($ad_data->{'template'} eq 'javascript') {
                $tmpl_vars{'ad_link'} = $ad_data->{'uri'};
            }
            else {
                $tmpl_vars{'ad_link'} = CLICKSERVER_URL . $ad_data->{'md5'};
                $tmpl_vars{'ad_text'} = $ad_data->{'ad_name'};
            }

            my $output = '';
            $template->process($ad_data->{'template'} . '.tmpl',
                               \%tmpl_vars, \$output)
              || die $template->error(), "\n";
            $self->{'ad_id'} = $ad_data->{'ad_id'};
            $self->{'_html'} = $output;
			$self->{'group_name'} = $ad_data->{'ad_group_name'};

            bless $self, $class;

            return $self;
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
    my ($class, $ad_group) = @_;
	my $ad_group_arrayref = $cache->get($ad_group);
	my $index = int(rand(scalar(@{$ad_group_arrayref})));
    $ad_group_arrayref->[$index];
}

sub as_html {
    my $self = shift;

    return $self->{'_html'};
}

sub log_view {
    my ($class, $ip, $ad) = @_;

    my $dbh = SL::Model->db_Main();
    my $sth = $dbh->prepare($log_view_sql); 
    $sth->bind_param(1, $ad->{'ad_id'});
    $sth->bind_param(2, $ip);
    my $rv = $sth->execute;
    $sth->finish;
	return 1 if $rv;
    return;
}

1;
