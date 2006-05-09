#!/usr/bin/env perl

use strict;
use warnings;

# make sure we are in a sane environment.
$ENV{MOD_PERL} or die "GATEWAY_INTERFACE not Perl!";

use lib $ENV{SL_ROOT} . "/clickserver/lib";

# Preload these modules during httpd startup, don't import any symbols
use Apache::DBI         ();
use Apache2::Const      ();
use Apache2::Log        ();
use Apache2::RequestIO  ();
use Apache2::RequestRec ();
use Apache2::RequestUtil();
use APR::Table            ();
use DBI                   ();
use DBD::Pg               ();
use SL::CS::Apache::Ad    ();
use SL::CS::Apache::Click ();
use SL::CS::Model         ();
use SL::CS::Model::Ad     ();

my $username = 'fred';
my $auth     = '';

my $db         = 'sl';
my $host       = 'localhost';
my $db_options = {
    RaiseError         => 1,
    PrintError         => 0,
    AutoCommit         => 0,
    FetchHashKeyName   => 'NAME_lc',
    ShowErrorStatement => 1,
    ChopBlanks         => 1,
};
my $dsn = "dbi:Pg:dbname='$db';host=$host";
$Apache::DBI::DEBUG=2;
Apache::DBI->connect_on_init( $dsn, $username, $auth, $db_options );
Apache::DBI->setPingTimeOut( $dsn, 3 );

1;
