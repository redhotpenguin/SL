package SL::App::Template;

use strict;
use warnings;

use SL::Config;

use Template;
use Template::Plugin::Date;
use base 'Template';

our ($Template, %Tmpl_global);

BEGIN {
  our $config = SL::Config->new;

  our %tmpl_config = ( INCLUDE_PATH => $config->sl_app_root . '/tmpl' );
  $Template = __PACKAGE__->SUPER::new( \%tmpl_config) || die $Template::ERROR;

  %Tmpl_global = ( base_uri => $config->sl_app_base_uri,
                 home_uri => $config->sl_app_home_uri,
                 css_uri  => $config->sl_app_css_uri, );
}

sub process {
  my ($self, $tmpl_name, $tmpl_data, $output_ref, $r) = @_;

  # data for all templates
  if ($r) {
 
 	if ($r->pnotes('session')) {
	    $tmpl_data->{msg} = delete $r->pnotes('session')->{msg};
            $tmpl_data->{session} = $r->pnotes('session');
	}
	$tmpl_data->{bug_url} = $r->unparsed_uri;
        $tmpl_data->{email} = $r->user;
        $tmpl_data->{reg}   = $r->pnotes($r->user);
  }
  my $ok = $self->SUPER::process( $tmpl_name, { %{$tmpl_data}, %Tmpl_global, },
                           $output_ref);

  return $ok if defined $ok;
  return;
}

sub template {
    return $Template;
}

1;
