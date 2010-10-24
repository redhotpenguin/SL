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

# core mp2
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

# sl
use SL::Search           ();
use SL::Search::Apache2  ();
use SL::Search::CityGrid ();

# cpan
use Apache2::Request                   ();
use Apache2::Connection::XForwardedFor ();
use URI                                ();
use HTTP::Headers::Util                ();

# dtrace identified these files as being loaded per request, so load them at startup
BEGIN {

    require 'utf8_heavy.pl';
    require 'unicore/To/Fold.pl';
}

print STDOUT "Startup.pl finished...\n";

1;
