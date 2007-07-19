package SL::App::Template;

use strict;
use warnings;

use SL::Config;
use Template;

our $TEMPLATE;

BEGIN {
    my $config = SL::Config->new;

    # setup our template object
    my %tmpl_config = ( INCLUDE_PATH => $config->sl_app_root . '/tmpl' );
    $TEMPLATE = Template->new( \%tmpl_config) || die $Template::ERROR;
}

sub template {
    return $TEMPLATE;
}

1;