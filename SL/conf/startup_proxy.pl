#!/usr/bin/env perl

use strict;
use warnings;

# make sure we are in a sane environment.
$ENV{MOD_PERL} or die "GATEWAY_INTERFACE not Perl!";

$|++;

use SL::Config ();
my $config = SL::Config->new();

print STDOUT "Loading modules...\n";

# single user mode
if ( $config->sl_debug or $config->sl_small_prof ) {
    require APR::Pool;
    require Apache::DB;
    Apache::DB->init();
}

# profiling
if ( $config->sl_prof ) {
    require Apache::DProf;
}

# status
if ( $config->sl_status ) {
    require Apache2::Status;
}

# Preload these modules during httpd startup, don't import any symbols
use Apache::DBI             ();
use Apache2::Connection     ();
use Apache2::ConnectionUtil ();
use Apache2::Log            ();
use Apache2::RequestIO      ();
use Apache2::RequestRec     ();
use Apache2::RequestUtil    ();
use Apache2::ServerRec      ();
use Apache2::ServerUtil     ();
use Apache2::SubRequest     ();
use Apache2::URI            ();
use Apache2::Const          ();
use APR::Table              ();

use SL::Model                ();
use SL::Model::Ad            ();
use SL::Model::Subrequest    ();
use SL::Model::RateLimit     ();
use SL::Model::URL           ();
use SL::Model::Proxy::Router ();

use SL::Apache::Proxy::AccessHandler          ();
use SL::Apache::Proxy::TransHandler           ();
use SL::Apache::Proxy::ResponseHandler        ();
use SL::Apache::Proxy::BlacklistHandler       ();
use SL::Apache::Proxy::PostReadRequestHandler ();
use SL::Apache::Proxy::PingHandler            ();
use SL::Apache::Proxy::LogHandler             ();

use SL::Cache         ();
use SL::UserAgent     ();
use SL::HTTP::Request ();
use SL::Util          ();

use RHP::Timer ();

use Digest::MD5 ();
use DBI         ();
use DBD::Pg     ();
DBI->install_driver('Pg');
use Data::Dumper     ();
use Sys::Load        ();
use Params::Validate ();
use Encode           ();
use Template         ();
use URI              ();
use Regexp::Assemble ();

print STDOUT "Modules loaded, initializing database connections\n";

$Apache::DBI::DEBUG = $config->sl_db_debug;
my $db_connect_params = SL::Model->connect_params;
Apache::DBI->connect_on_init( @{$db_connect_params} );
Apache::DBI->setPingTimeOut( $db_connect_params->[0],
    $config->sl_db_ping_timeout );

print STDOUT "Startup.pl finished...\n";

1;
