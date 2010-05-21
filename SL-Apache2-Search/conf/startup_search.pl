#!/usr/bin/perl

use strict;
use warnings;

# make sure we are in a sane environment.
$ENV{MOD_PERL} or die "GATEWAY_INTERFACE not Perl!";

$|++;

use SL::Config ();
my $config = SL::Config->new();

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
use SL::Config                         ();
use SL::Apache2::Search                ();
use SL::Search ();

# cpan
use Apache2::Request                   ();
use Apache2::Connection::XForwardedFor ();
use URI                                ();
use HTTP::Headers::Util                ();
use Net::Amazon  ();
use HTML::Entities ();
use HTML::Template ();


# dtrace identified these files as being loaded per request, so load them at startup
BEGIN {

    require 'utf8_heavy.pl';
    require 'unicore/To/Fold.pl';
}

print STDOUT "Startup.pl finished...\n";

1;
