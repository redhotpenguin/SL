package SL::Apache::App;

use strict;
use warnings;

use Apache2::Const -compile => qw(OK SERVER_ERROR NOT_FOUND M_GET M_POST);
use Apache2::Log ();

# setup our template object
use SL::Config;
my $config = SL::Config->new;

use Template;
my %tmpl_config = ( INCLUDE_PATH => $config->tmpl_root . '/app' );
my $tmpl = Template->new( \%tmpl_config) || die $Template::ERROR;

=head1 METHODS

=over 4

=item C<dispatch_index>

This method serves of the master ad control panel for now

=back

=cut

sub dispatch_index {
	my ($self, $r) = @_;

	my %tmpl_data = ( root => $r->pnotes('root'),
                       email => $r->user);
	my $output;
	my $ok = $tmpl->process('home.tmpl', \%tmpl_data, \$output);
	$ok ? return $self->ok($r, $output) 
		: return $self->error($r, "Template error: " . $tmpl->error());
}

sub ok {
	my ($self, $r, $output) = @_;
	# send successful response
	$r->content_type('text/html');
	$r->print($output);
	return Apache2::Const::OK;
}

sub error {
	my ($self, $r, $error) = @_;
	$r->log->error($error);
	return Apache2::Const::SERVER_ERROR;
}

1;
