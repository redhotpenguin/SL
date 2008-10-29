#!/usr/bin/perl

use strict;
use warnings;

# make sure we are in a sane environment.
$ENV{MOD_PERL} or die "GATEWAY_INTERFACE not Perl!";

$|++;

print "Loading modules...\n";

use SL::Config ();

our $Config = SL::Config->new();

use Apache2::RequestRec ();
use Apache2::Log        ();
use Apache2::Connection ();
use Apache2::ServerUtil ();

use LWP::UserAgent      ();

use SL::CP           ();
use SL::CP::IPTables ();

print "Initializing firewall...\n";
SL::CP::IPTables->init_firewall;

# register cleanup
Apache2::ServerUtil::server_shutdown_cleanup_register(
    \SL::CP::IPTables->clear_firewall );

print "Startup.pl finished...\n";

1;
