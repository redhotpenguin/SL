#!/usr/bin/env perl

use strict;
use warnings;

# make sure we are in a sane environment.
$ENV{MOD_PERL} or die "GATEWAY_INTERFACE not Perl!";

$|++;

use FindBin;
use lib "$FindBin::Bin/../lib";

use SL::Config                    ();
my @config_files =
  ("$FindBin::Bin/../sl.conf", "$FindBin::Bin/../conf/sl.conf");
my $config = SL::Config->new(\@config_files);
print STDOUT "Loading modules...\n";

# FIXME - link to sl_debug option
#use APR::Pool ();
#use Apache::DB ();
#Apache::DB->init();

# Preload these modules during httpd startup, don't import any symbols
use Apache::DBI             ();
use Apache2::Connection     ();
use Apache2::ConnectionUtil ();
use Apache2::Log            ();
use Apache2::Request        ();
use Apache2::RequestIO      ();
use Apache2::RequestRec     ();
use Apache2::RequestUtil();
use Apache2::ServerRec            ();
use Apache2::ServerUtil           ();
use Apache2::SubRequest           ();
use APR::Table                    ();
use HTTP::Cookies                 ();
use HTTP::Headers                 ();
use HTTP::Request                 ();
use HTTP::Response                ();
use SL::CS::Apache::Ad            ();
use SL::CS::Apache::Click         ();
use SL::CS::Model                 ();
use SL::CS::Model::Ad             ();
use SL::Model::Ad                 ();
use SL::Apache                    ();
use SL::Apache::Reg               ();
use SL::Apache::PerlAccessHandler ();
use SL::Apache::PerlTransHandler  ();
use SL::Cache                     ();
use SL::UserAgent                 ();
use SL::Util                      ();
use DBI                           ();
use DBD::Pg                       ();
use Data::Dumper qw(Dumper);

print STDOUT "Modules loaded, initializing database connections\n";

$Apache::DBI::DEBUG = $config->db_debug;
my $db_connect_params = $config->db_connect_params;
Apache::DBI->connect_on_init(@{$db_connect_params});
Apache::DBI->setPingTimeout($db_connect_params->[0], $config->db_ping_timeout);

print STDOUT "Startup.pl finished...\n";

1;
