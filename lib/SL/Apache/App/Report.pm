package SL::Apache::App::Report;

use strict;
use warnings;

use Apache2::Const -compile => qw( OK);
use Apache2::Log ();

use base 'SL::Apache::App';

use SL::Config;
my $config = SL::Config->new;

use Template;
my %tmpl_config = ( INCLUDE_PATH => $config->tmpl_root . '/app' );
my $tmpl = Template->new( \%tmpl_config) || die $Template::ERROR;

sub dispatch_index {
    my ( $self, $r ) = @_;

    my %tmpl_data = ( root => $r->pnotes('root'), 
                        reg => $r->pnotes( $r->user) );

    my $output;
    my $ok = $tmpl->process('report.tmpl', \%tmpl_data, \$output);
    $ok ? return $self->ok($r, $output)
        : return $self->error($r, "Template error: " . $tmpl->error());
}

1;

__END__

    my @DAYS = qw( 1 3 7 14 30 );

    # generate the results
    my $start = DateTime->now;
    my $end   = DateTime->now;
    my %results;
    foreach my $day (@DAYS) {
        my $end = DateTime->now->subtract( days => $day );
        $results{$day}{views}  = SL::CS::Model::Report->views( $end, $start );
        $results{$day}{clicks} = SL::CS::Model::Report->links( $end, $start );
    }

    my %tmpl_data;
    my $output;
    my $ok = $tmpl->process( 'ad/report.tmpl', \%tmpl_data, \$output );
}
