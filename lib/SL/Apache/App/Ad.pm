package SL::Apache::App::Ad;

use strict;
use warnings;

use Apache2::Const -compile => qw(OK SERVER_ERROR NOT_FOUND);
use Apache2::Log;
use Apache2::Request;

# setup our template object
use SL::Config;
my $config = SL::Config->new;

use Template;
my %tmpl_config = ( INCLUDE_PATH => $config->tmpl_root . '/app/ad' );
my $tmpl = Template->new( \%tmpl_config) || die $Template::ERROR;

# this specific template logic
use Data::Dumper;
use SL::Model;
use SL::Model::App; # works for now
my $schema = SL::Model::App->connect(SL::Model->connect);

=head1 METHODS

=over 4

=item C<dispatch_index>

This method serves of the master ad control panel for now

=back

=cut

sub dispatch_index {
	my ($self, $r) = @_;
	my %tmpl_data;
	# grab the ads
	@{$tmpl_data{'ads'}} = SL::Model::App->resultset('Ad')->all;
	my %tmpl_vars = ( ads => $tmpl_data{ads} );
	my $output;
	my $ok = $tmpl->process('list.tmpl', \%tmpl_vars,\$output);
	$ok ? return ok($r, $output) 
		: return error($r, "Template error: " . $tmpl->error());
}

sub dispatch_edit {
	my ($self, $r) = @_;
	my $req = Apache2::Request->new($r);
	my $ad_id = $req->param('ad_id');
	return Apache2::Const::NOT_FOUND unless $ad_id;

	my ($ad) = SL::Model::App->resultset('Ad')->search({ ad_id => $ad_id });
	my $output;
	my $ok = $tmpl->process('edit.tmpl', { ad => $ad }, \$output);
	$ok ? return ok($r, $output) 
		: return error($r, "Template error: " . $tmpl->error());
}

sub dispatch_add {
	my ($self, $r) = @_;
	my $output;
	my $ok = $tmpl->process('add.tmpl', undef, \$output);	
}

sub ok {
	my ($r, $output) = @_;
	# send successful response
	$r->content_type('text/html');
	$r->print($output);
	return Apache2::Const::OK;
}

sub error {
	my ($r, $error) = @_;
	$r->log->error($error);
	return Apache2::Const::SERVER_ERROR;
}

1;