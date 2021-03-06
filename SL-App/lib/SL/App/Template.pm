package SL::App::Template;

use strict;
use warnings;

use Config::SL;

use Template;
use Template::Plugin::Date;
use Template::Plugin::Number::Format;
use base 'Template';

our ( $Template, %Tmpl_global );

BEGIN {
    our $config = Config::SL->new;

    our %tmpl_config = ( INCLUDE_PATH => '/var/www/app.slwifi.com' . '/tmpl' );
    $Template = __PACKAGE__->SUPER::new( \%tmpl_config )
      || die $Template::ERROR;

    %Tmpl_global = (
        base_uri => $config->sl_app_base_uri,
        home_uri => $config->sl_app_home_uri,
    );
}

sub process {
    my ( $self, $tmpl_name, $tmpl_data, $output_ref, $r ) = @_;

    # data for all templates
    if ($r) {

        if ( $r->pnotes('session') ) {

            # pull the session msg off
            $tmpl_data->{msg}     = delete $r->pnotes('session')->{msg};
            $tmpl_data->{session} = $r->pnotes('session');
        }

        $tmpl_data->{bug_url} = $r->unparsed_uri;
        $tmpl_data->{email}   = $r->user;
        $tmpl_data->{reg}     = $r->pnotes( $r->user );
    }
    $self->SUPER::process( $tmpl_name, { %{$tmpl_data}, %Tmpl_global, },
        $output_ref )
      || return;
    return 1;
}

sub template {
    return $Template;
}

1;
