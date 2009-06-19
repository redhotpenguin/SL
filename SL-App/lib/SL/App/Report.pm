package SL::App::Report;

use strict;
use warnings;

use Apache2::Const -compile => qw( OK M_POST M_GET REDIRECT );
use Apache2::Log ();

use base 'SL::App';

our %Types = ( 'views' => 'Ad Insertions', 'users' => 'Unique Users');

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
    my $type = $req->param('type') || 'views';
    my $reg      = $r->pnotes( $r->user );

    my $report_base = join('/', 
    	$reg->account->report_base, $type . '_' . $temporal . '.png' );

    my $report_uri;
    if (-f join('/', $Config->sl_data_root, $report_base)) {

	    $report_uri = join( '/', $Config->sl_app_base_uri, '/img/reports', $report_base);
    }

    if ( $r->method_number == Apache2::Const::M_GET ) {
        my %tmpl_data = (
            types                  => \%Types,
            type                   => $type,
            temporals              => \%Temporals,
            status                 => $req->param('status') || '',
            report_email_frequency => $reg->report_email_frequency,
            temporal               => $temporal,
        );

	if ($report_uri) {
		$tmpl_data{report_uri} = $report_uri;
	}

        my $output;
        $tmpl->process( 'report.tmpl', \%tmpl_data, \$output, $r ) ||
          return $self->error( $r, $tmpl->error );
        return $self->ok( $r, $output );
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
