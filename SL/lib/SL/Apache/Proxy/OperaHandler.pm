package SL::Apache::Proxy::OperaHandler;

use strict;
use warnings;

use constant DEBUG => $ENV{SL_DEBUG} || 0;

use Apache2::Const -compile => qw( OK );

use SL::Config;
use Template;

our $CONFIG;
our $TEMPLATE_OUTPUT;

BEGIN {
    $CONFIG = SL::Config->new;

    our $PATH = $CONFIG->sl_root . '/tmpl/';

    die "Template include path $PATH doesn't exist!\n" unless -d $PATH;

    my %TMPL_CONFIG = (
        ABSOLUTE     => 1,
        INCLUDE_PATH => $PATH,
    );

    our $TEMPLATE = Template->new( \%TMPL_CONFIG ) || die $Template::ERROR;

    $TEMPLATE->process( 'opera.tmpl', {}, \$TEMPLATE_OUTPUT )
      || die $TEMPLATE->error();
}

sub handler {
    my $r = shift;

    $r->server->add_version_component('sl');
    $r->no_cache(1);
    $r->content_type('text/html');

    $r->print($TEMPLATE_OUTPUT);

    return Apache2::Const::OK;
}

1;
