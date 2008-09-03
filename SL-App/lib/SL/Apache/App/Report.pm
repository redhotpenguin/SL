package SL::Apache::App::Report;

use strict;
use warnings;

use Apache2::Const -compile => qw( OK M_POST M_GET REDIRECT );
use Apache2::Log ();

use base 'SL::Apache::App';

our %Types = ( 'views' => 'Ad Views', );

our %Temporals = (
    'daily'      => '24 hours',
    'weekly'     => '7 days',
    'monthly'    => '30 days',
    'quarterly'  => '90 days',
    'biannually' => '6 months',
    'annually'   => '12 months',
);

use SL::App::Template ();
our $tmpl = SL::App::Template->template();

use SL::Config;
our $Config = SL::Config->new;

sub dispatch_index {
    my ( $self, $r ) = @_;

    my $req      = Apache2::Request->new($r);
    my $temporal = $req->param('temporal') || 'daily';
    my $reg      = $r->pnotes( $r->user );

    my $report_uri = join( '/', $Config->sl_app_report_uri,
    	$reg->account_id->report_base, 'views_' . $temporal . '.png' );

    # fetch the report
    my $response = $self->SUPER::ua->get( URI->new($report_uri) );
    undef $report_uri unless $response->is_success;

    if ( $r->method_number == Apache2::Const::M_GET ) {
        my %tmpl_data = (
            temporals              => \%Temporals,
            report_uri             => $report_uri,
            status                 => $req->param('status') || '',
            report_email_frequency => $reg->report_email_frequency,
            temporal               => $temporal,
        );

        my $output;
        my $ok = $tmpl->process( 'report.tmpl', \%tmpl_data, \$output, $r );

        return $self->ok( $r, $output ) if $ok;
        return $self->error( $r, "Template error: " . $tmpl->error() );
    }
    elsif ( $r->method_number == Apache2::Const::M_POST ) {

        $r->method_number(Apache2::Const::M_GET);

        # update the status
        $r->pnotes( $r->user )
          ->report_email_frequency( $req->param('report_email_frequency') );
        $r->pnotes( $r->user )->update;


    $r->headers_out->set(
        Location => 
            $r->construct_url( $r->uri . "?temporal=$temporal&status=updated" ));
    return Apache2::Const::REDIRECT;
    }
}

1;

__END__
