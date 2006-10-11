package SL::Apache::App::Ad;

use strict;
use warnings;

use Apache2::Const -compile => qw(OK SERVER_ERROR NOT_FOUND M_GET M_POST);
use Apache2::Log ();
use Apache2::SubRequest ();
use CGI ();
use Data::FormValidator ();

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
	my $ok = $tmpl->process('list.tmpl', \%tmpl_data,\$output);
	$ok ? return ok($r, $output) 
		: return error($r, "Template error: " . $tmpl->error());
}

my %ad_profile = (
	required => [qw( name text ad_group_id active template)],
);

sub dispatch_edit {
	my ($self, $r) = @_;
	# check the query parameters
	my ($key, $ad_id) = split('=', $r->args);
	return Apache2::Const::SERVER_ERROR
		unless (($key eq 'ad_id') && ($ad_id =~ m/^-?\d+$/));
	my (%tmpl_data, $ad, $output);
	if ($ad_id > 0) { # edit existing ad
		# grab the ad
		($ad) = SL::Model::App->resultset('Ad')->search({ ad_id => $ad_id });
		return Apache2::Const::NOT_FOUND unless $ad;
    	$tmpl_data{'ad'} = $ad;
	}
	if ($r->method_number == Apache2::Const::M_GET) {
		# serve the form
		@{$tmpl_data{'ad_groups'}} = SL::Model::App->resultset('AdGroup')->all;
		my $ok = $tmpl->process('edit.tmpl', \%tmpl_data, \$output);
		$ok ? return ok($r, $output) 
			: return error($r, "Template error: " . $tmpl->error());
    } elsif ($r->method_number == Apache2::Const::M_POST) {
		my $cgi = CGI->new($r);
		my $results = Data::FormValidator->check($cgi, \%ad_profile);
		if ($results->has_missing or $results->has_invalid) {
			%{$tmpl_data{'missing'}} = map { $_ => 1 } $results->missing;
			%{$tmpl_data{'invalid'}} = map { $_ => 1 } $results->invalid;
		    my $ok = $tmpl->process('edit.tmpl', \%tmpl_data, \$output);
		}
		foreach my $attr qw( name text active ad_group_id template ) {
			$ad->$attr($cgi->param($attr));
		}
		$ad->update;
		$r->internal_redirect('/app/ad');
		return Apache2::Const::OK;
	}
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