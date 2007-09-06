package SL::App::Template;

use strict;
use warnings;

use SL::Config;

use Template;
use Template::Plugin::Date;
use base 'Template';

our ($TEMPLATE, %TMPL_DATA);

BEGIN {
  our $config = SL::Config->new;

  our %tmpl_config = ( INCLUDE_PATH => $config->sl_app_root . '/tmpl' );
  $TEMPLATE = __PACKAGE__->SUPER::new( \%tmpl_config) || die $Template::ERROR;

  %TMPL_DATA = ( base_uri => $config->sl_app_base_uri,
                 home_uri => $config->sl_app_home_uri,
                 css_uri  => $config->sl_app_css_uri, );
}

sub process {
  my ($self, $tmpl_name, $data_hashref, $output_ref, $r) = @_;

  if ($r) {
	my $bug_url = $r->unparsed_uri;
  $data_hashref->{bug_url} = $bug_url;
	}
my $ok = $self->SUPER::process( $tmpl_name, { %{$data_hashref}, %TMPL_DATA },
                           $output_ref);

  return $ok if defined $ok;
  return;
}

sub template {
    return $TEMPLATE;
}

1;
