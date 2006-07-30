package SL::CS::Model::Ad;

use strict;
use warnings;

use SL::CS::Model;
$SL::Debug = 0;
our @ads;

BEGIN {
    refresh_ads();

    sub refresh_ads {
        undef @ads;

        # Load all the ads into a shared global
        my $dbh = SL::CS::Model->db_Main();
        my $sql = <<SQL;
SELECT
ad.ad_id, 
ad.name, 
link.md5, 
ad.template 
FROM ad 
LEFT JOIN link 
USING (ad_id)
WHERE ad.active = 't'
SQL

        my $sth = $dbh->prepare_cached($sql);
        my $rv  = $sth->execute;
        die unless $rv;

        while ( my $ad_data = $sth->fetchrow_hashref ) {
            require Data::Dumper;
            my $ad = SL::CS::Model::Ad->new($ad_data);
            print STDERR "Ad: " . Data::Dumper::Dumper($ad);
            push @ads, $ad;
        }

        $dbh->commit;

        sub new {
            my ( $class, $ad_data ) = @_;
            my $self = {};

            require Template;
			require SL::Config;
			my $cfg = SL::Config->new;
			my $app_root = join("/", $cfg->sl_root, $cfg->sl_version);
			print STDERR "Looking for template at $app_root/tmpl/\n";
            my $tmpl_config = {
                ABSOLUTE     => 1,
                INCLUDE_PATH => "$app_root/tmpl/",
            };
            my $ad_server = 'http://h1.redhotpenguin.com:7777/click';
            my $template = Template->new($tmpl_config) || die $Template::ERROR,
              "\n";
            my %tmpl_vars = (
                sl_link => "$ad_server/795da10ca01f942fd85157d8be9e832e",
                ad_link => "$ad_server/" . $ad_data->{'md5'},
                ad_text => $ad_data->{'name'},
            );
            my $output = '';
            $template->process( $ad_data->{'template'} . '.tmpl',
                \%tmpl_vars, \$output )
              || die $template->error(), "\n";
            $self->{'ad_id'} = $ad_data->{'ad_id'};
            $self->{'_html'} = $output;

            bless $self, $class;

            return $self;
        }
    }
}

sub random {
    my $class = shift;
    refresh_ads() if $SL::Debug;
    my $index = int( rand( scalar(@ads) ) );
    return $ads[$index];
}

sub as_html {
    my $self = shift;

    return $self->{'_html'};
}
1;
