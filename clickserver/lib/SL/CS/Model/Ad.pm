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
SELECT *
FROM ad
WHERE active = 't'
SQL

        my $sth = $dbh->prepare_cached($sql);
        my $rv  = $sth->execute;
        die unless $rv;
        while ( my $ad_data = $sth->fetchrow_hashref ) {
			require Data::Dumper;
			print STDERR "Ad data: " . Data::Dumper::Dumper($ad_data);
			push @ads, SL::CS::Model::Ad->new($ad_data);
        }

        $dbh->commit;

        sub new {
            my ( $class, $ad_data ) = @_;
            my $self = {};

            $self->{$_} = $ad_data->{$_} for keys %{$ad_data};
            bless $self, $class;

            return $self;
        }
    }
}

sub random {
    my $class = shift;
    refresh_ads() if $SL::Debug;
    my $index = int( rand( scalar(@ads) ) );
require Data::Dumper;
	print STDERR "Ads are " . Data::Dumper::Dumper(\@ads);
	print STDERR "****\n\n****\nMY INDEX IS $index\n****\n****\n";
    return $ads[$index];
}

sub as_html {
    my $self = shift;
    if ( defined $self->{'_html'} ) {
        return $self->{'_html'};
    }

    # Ok it's not cached
    my $template = $ENV{SL_ROOT} . "/clickserver/tmpl/$self->{'template'}.tmpl";

    open( FH, "< $template" )
      or die "template => $template, err: $!\n";
    $self->{'_html'} = do { local $/; <FH> };
    close(FH);
    return $self->{'_html'};
}
1;
