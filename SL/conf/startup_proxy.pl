#!/usr/bin/env perl

use strict;
use warnings;

# make sure we are in a sane environment.
$ENV{MOD_PERL} or die "GATEWAY_INTERFACE not Perl!";

$|++;

use SL::Config ();
my $config = SL::Config->new();

print STDOUT "Starting SL::Proxy server on port "
  . $config->sl_proxy_apache_listen . "\n";
print STDOUT "Loading modules...\n";

# status
if ( $config->sl_status ) {
    use Apache2::Status;
}

# Preload these modules during httpd startup, don't import any symbols
use Apache::DBI             ();
use Apache2::Connection     ();
use Apache2::ConnectionUtil ();
use Apache2::Log            ();
use Apache2::RequestIO      ();
use Apache2::RequestRec     ();
use Apache2::RequestUtil    ();
use Apache2::Response       ();
use Apache2::ServerRec      ();
use Apache2::ServerUtil     ();
use Apache2::SubRequest     ();
use Apache2::URI            ();
use Apache2::Const          ();
use Apache2::Filter         ();
use APR::Table              ();

use SL::Model                          ();
use SL::Model::Ad                      ();
use SL::Model::URL                     ();
use SL::Model::Proxy::Router           ();
use SL::Model::Proxy::Location         ();
use SL::Model::Proxy::Router::Location ();

use SL::Apache::Proxy::AccessHandler          ();
use SL::Apache::Proxy::TransHandler           ();
use SL::Apache::Proxy::ResponseHandler        ();
use SL::Apache::Proxy::SplashHandler          ();
use SL::Apache::Proxy::OperaHandler           ();
use SL::Apache::Proxy::BlacklistHandler       ();
use SL::Apache::Proxy::PostReadRequestHandler ();
use SL::Apache::Proxy::PingHandler            ();
use SL::Apache::Proxy::LogHandler             ();

use SL::Static       ();
use SL::Cache        ();
use SL::Subrequest   ();
use SL::RateLimit    ();
use SL::HTTP::Client ();
use SL::BrowserUtil  ();
use SL::User         ();
use SL::Context      ();

use Digest::MD5 ();
use DBI         ();
use DBD::Pg     ();
DBI->install_driver('Pg');
use Sys::Load           ();
use Encode              ();
use Template            ();
use URI                 ();
use URI::http           ();
use URI::Escape         ();
use Regexp::Assemble    ();
use Compress::Zlib      ();
use Compress::Bzip2     ();
use Crypt::Blowfish_PP  ();
use HTTP::Headers::Util ();
use Cache::Memcached    ();
use Net::DNS            ();

BEGIN {

    require 'utf8_heavy.pl';
    require 'unicore/PVA.pl';
    require 'unicore/Exact.pl';
    require 'unicore/Canonical.pl';
    require 'unicore/To/Fold.pl';
    require 'unicore/lib/gc_sc/SpacePer.pl';
}

$Apache::DBI::DEBUG = $config->sl_db_debug;
my $db_connect_params = SL::Model->connect_params;
Apache::DBI->connect_on_init( @{$db_connect_params} );
Apache::DBI->setPingTimeOut( $db_connect_params->[0],
    $config->sl_db_ping_timeout );

# delete this line and I will beat you with a stick
# we need to disconnect before the fork
SL::Model->connect->disconnect;
$DBI::connect_via = 'Apache::DBI::connect';

print STDOUT "Startup.pl finished...\n";

1;
