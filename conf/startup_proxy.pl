#!/usr/bin/env perl

use strict;
use warnings;

# make sure we are in a sane environment.
$ENV{MOD_PERL} or die "GATEWAY_INTERFACE not Perl!";

$|++;

my $config;

BEGIN {
    use FindBin;
    use lib "$FindBin::Bin/../lib";

    require SL::Config;
    my @config_files =
      ("$FindBin::Bin/../sl.conf", "$FindBin::Bin/../conf/sl.conf");

    $config = SL::Config->new(\@config_files);

}
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
use Apache2::ServerRec               ();
use Apache2::ServerUtil              ();
use Apache2::SubRequest              ();
use APR::Table                       ();
use HTTP::Cookies                    ();
use HTTP::Headers                    ();
use HTTP::Request                    ();
use HTTP::Response                   ();
use SL::Model                        ();
use SL::Model::Ad                    ();
use SL::Apache::Click                ();
use SL::Apache::Reg                  ();
use SL::Apache::ProxyAccessHandler   ();
use SL::Apache::ProxyTransHandler    ();
use SL::Apache::ProxyResponseHandler ();
use SL::Cache                        ();
use SL::DB                           ();
use SL::UserAgent                    ();
use SL::Util                         ();
use DBI                              ();
use DBD::Pg                          ();
use Data::Dumper qw(Dumper);

print STDOUT "Modules loaded, initializing database connections\n";

$Apache::DBI::DEBUG = $config->sl_db_debug;
my $db_connect_params = SL::DB->connect_params;
Apache::DBI->connect_on_init(@{$db_connect_params});
Apache::DBI->setPingTimeOut($db_connect_params->[0],
                            $config->sl_db_ping_timeout);

print STDOUT "Startup.pl finished...\n";

1;
