package SL::Apache::App::Report;

use strict;
use warnings;

use Apache2::Const -compile => qw( OK M_POST M_GET);
use Apache2::Log ();

use base 'SL::Apache::App';

our %TYPES = (
    'views'  => 'Ad Views',
    'clicks' => 'Ad Clicks',
    'rates'  => 'Click Rate',
    'ads'    => 'Which Ads?',
);
our %TEMPORALS = (
    'daily'     => '24 hours',
    'weekly'    => '7 days',
    'monthly'   => '30 days',
    'quarterly' => '90 days',
    'biannually' => '6 months',
    'annually' => '12 months',
);

use SL::App::Template ();
our $tmpl = SL::App::Template->template();

use SL::Config;
my $config = SL::Config->new;

sub dispatch_index {
    my ( $self, $r ) = @_;

    my $req      = Apache2::Request->new($r);
    my $temporal = $req->param('temporal') || 'daily';
    my $type     = $req->param('type') || 'views';
    my $reg = $r->pnotes($r->user);

    my $report_uri = join('/', $config->sl_app_report_uri, $reg->report_base);

    if ( $r->method_number == Apache2::Const::M_GET ) {
        my %tmpl_data = (
            types                  => \%TYPES,
            temporals              => \%TEMPORALS,
            report_uri             => $report_uri,
            reg                    => $reg,
            status                 => $req->param('status') || '',
            report_email_frequency => $reg->report_email_frequency,
            temporal => $temporal,
            type     => $type,
        );

        my $output;
        my $ok = $tmpl->process( 'report.tmpl', \%tmpl_data, \$output );
        $ok
          ? return $self->ok( $r, $output )
          : return $self->error( $r, "Template error: " . $tmpl->error() );
    }
    elsif ( $r->method_number == Apache2::Const::M_POST ) {

        # update the status
        $r->pnotes( $r->user )->report_email_frequency(
                 $req->param('report_email_frequency'));
        $r->pnotes( $r->user )->update;

        $r->method_number(Apache2::Const::M_GET);
        $r->internal_redirect(
            $r->construct_url( $r->uri . "?temporal=$temporal&status=updated" )
        );
        return Apache2::Const::OK;
    }
}

1;

__END__
