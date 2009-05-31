#!/usr/bin/perl

use strict;
use warnings;

# make sure we are in a sane environment.
$ENV{MOD_PERL} or die "GATEWAY_INTERFACE not Perl!";

$|++;

use FindBin;
use lib "$FindBin::Bin/../lib";

use SL::Config;
my $config = SL::Config->new();

print STDOUT "Starting SL::App server on port "
  . $config->sl_app_http_port . "\n";
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
use Apache2::Request        ();
use Apache2::RequestIO      ();
use Apache2::Request        ();
use Apache2::RequestRec     ();
use Apache2::RequestUtil    ();
use Apache2::ServerRec      ();
use Apache2::ServerUtil     ();
use Apache2::SubRequest     ();
use Apache2::Upload         ();
use APR::Table              ();

use DBI     ();
use DBD::Pg ();
DBI->install_driver('Pg');
use DBIx::Class                 ();
use DBIx::Class::Schema::Loader ();


use SL::App                         ();
use SL::App::Template               ();
use SL::App::Ad                     ();
use SL::App::Ad::Bugs               ();
use SL::App::Ad::Msg                     ();
use SL::App::Ad::Twitter              ();
use SL::App::Ad::Groups              ();
use SL::App::Ad::Groups::Ads              ();
use SL::App::Billing                ();
use SL::App::Blacklist              ();
use SL::App::CookieAuth             ();
use SL::App::CP                     ();
use SL::App::CPAuthHandler          ();
use SL::App::Home                   ();
use SL::App::Logon                  ();
use SL::App::PostReadRequestHandler ();
use SL::App::Report                 ();
use SL::App::Router                 ();
use SL::App::Settings               ();
use SL::Model                       ();
use SL::Model::App                  ();
use SL::Model::Report               ();

use Apache::Session::DB_File ();
use Data::Dumper qw(Dumper);
use Data::FormValidator         ();
use Crypt::CBC                  ();
use Crypt::DES                  ();
use XML::Feed                   ();
use XML::LibXML                 ();
use CGI ();
CGI->compile(':all');

#use JavaScript::Minifier::XS    ();

print STDOUT "Modules loaded, initializing database connections\n";

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
