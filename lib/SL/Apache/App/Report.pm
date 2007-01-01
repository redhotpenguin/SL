package SL::Apache::App::Report;

use strict;
use warnings;

use Apache2::Const -compile => qw( OK M_POST M_GET);
use Apache2::Log ();

use base 'SL::Apache::App';

use SL::Config;
my $config = SL::Config->new;

use Template;
my %tmpl_config = ( INCLUDE_PATH => $config->tmpl_root . '/app' );
my $tmpl = Template->new( \%tmpl_config) || die $Template::ERROR;

sub dispatch_index {
    my ( $self, $r ) = @_;

	my $req = Apache2::Request->new($r);
    my $temporal = $req->param('temporal') || 'daily';
    my $accessor = "send_reports_$temporal";

    if ($r->method_number == Apache2::Const::M_GET ) {
        my %tmpl_data = ( root => $r->pnotes('root'), 
                           reg => $r->pnotes( $r->user),
                           status => $req->param('status') || '',
                           send_report => $r->pnotes($r->user)->$accessor,
                           temporal => $temporal );

        my $output;
        my $ok = $tmpl->process('report.tmpl', \%tmpl_data, \$output);
        $ok ? return $self->ok($r, $output)
          : return $self->error($r, "Template error: " . $tmpl->error());
    }
    elsif ($r->method_number == Apache2::Const::M_POST ) {
        return $self->error($r, "$self: Missing params") unless ($temporal);
        # update the status 
        my $val = ($req->param('send_report') eq 'on') ? 1 : 0;
        $r->pnotes($r->user)->$accessor($val);
        $r->pnotes($r->user)->update;

        $r->method_number(Apache2::Const::M_GET);
        $r->internal_redirect($r->construct_url(
             $r->uri . "?temporal=$temporal&status=updated"));
        return Apache2::Const::OK;
    }
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
