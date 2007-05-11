#!/usr/bin/env perl

use strict;
use warnings;

# make sure we are in a sane environment.
$ENV{MOD_PERL} or die "GATEWAY_INTERFACE not Perl!";

$|++;

use FindBin ();
use lib "$FindBin::Bin/../lib";

use SL::Config ();
my $config = SL::Config->new();

print STDOUT "Loading modules...\n";

# FIXME - link to sl_debug option
#use APR::Pool ();
#use Apache::DB ();
#Apache::DB->init();

# Preload these modules during httpd startup, don't import any symbols
use Apache::DBI                         ();
use Apache2::Connection                 ();
use Apache2::ConnectionUtil             ();
use Apache2::Log                        ();
use Apache2::RequestIO                  ();
use Apache2::RequestRec                 ();
use Apache2::RequestUtil                ();
use Apache2::ServerRec                  ();
use Apache2::ServerUtil                 ();
use Apache2::SubRequest                 ();
use Apache2::Status                     ();
use APR::Table                          ();

use SL::Model                           ();
use SL::Model::Ad                       ();
use SL::Model::Subrequest               ();
use SL::Model::Ratelimit                ();
use SL::Model::URL                      ();

use SL::Apache::Proxy::TransHandler     ();
use SL::Apache::Proxy::ResponseHandler  ();
use SL::Apache::Proxy::BlacklistHandler ();
use SL::Apache::Proxy::LogHandler       ();

use SL::Cache                           ();
use SL::UserAgent                       ();
use SL::HTTP::Request                   ();
use SL::Util                            ();

use RHP::Timer                          ();

use Digest::MD5                         ();
use DBI                                 ();
DBI->install_driver('Pg')               ();
use DBD::Pg                             ();
use Data::Dumper                        ();
use Sys::Load                           ();
use Params::Validate                    ();
use Encode                              ();
use Template                            ();
use URI                                 ();
use Regexp::Assemble                    ();

print STDOUT "Modules loaded, initializing database connections\n";

$Apache::DBI::DEBUG = $config->sl_db_debug;
my $db_connect_params = SL::Model->connect_params;
Apache::DBI->connect_on_init(@{$db_connect_params});
Apache::DBI->setPingTimeOut($db_connect_params->[0],
                            $config->sl_db_ping_timeout);

print STDOUT "Startup.pl finished...\n";

1;
