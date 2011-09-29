#!/usr/bin/perl

use strict;
use warnings;

# make sure we are in a sane environment.
$ENV{MOD_PERL} or die "GATEWAY_INTERFACE not Perl!";

$|++;

use Config::SL ();
my $config = Config::SL->new();

print STDOUT "Starting SL::Search server on port "
  . $config->sl_apache_listen . "\n";
print STDOUT "Loading modules...\n";

# status
if ( $config->sl_status ) {
    use Apache2::Status;
}

# sl
use SL::Search           ();
use SL::Search::Apache2  ();
use SL::Search::CityGrid ();
use SL::Model::App ();
use SL::Model::App::Network ();

# dtrace identified these files as being loaded per request, so load them at startup
BEGIN {

    require 'utf8_heavy.pl';
    require 'unicore/To/Fold.pl';
}

print STDOUT "Modules loaded, initializing database connections\n";
use Apache::DBI;
$Apache::DBI::DEBUG = $config->sl_db_debug;
my $db_connect_params = SL::Model->connect_params;
Apache::DBI->connect_on_init( @{$db_connect_params} );
Apache::DBI->setPingTimeOut( $db_connect_params->[0],
    $config->sl_db_ping_timeout );

# delete this line and I will beat you with a stick
SL::Model->connect->disconnect;
$DBI::connect_via = 'Apache::DBI::connect';

print STDOUT "Startup.pl finished...\n";

1;
