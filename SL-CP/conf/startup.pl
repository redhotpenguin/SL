#!/usr/bin/perl

use strict;
use warnings;

# make sure we are in a sane environment.
$ENV{MOD_PERL} or die "GATEWAY_INTERFACE not Perl!";

$|++;

use SL::Config ();

our $Config = SL::Config->new();

use Apache2::RequestRec ();
use Apache2::Log        ();
use Apache2::Connection ();

use SL::CP           ();
use SL::CP::IPTables ();

print "Startup.pl finished...\n";

1;
