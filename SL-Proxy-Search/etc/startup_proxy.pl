#!/usr/local/bin/perl

use strict;
use warnings;

# make sure we are in a sane environment.
$ENV{MOD_PERL} or die "GATEWAY_INTERFACE not Perl!";

$|++;

use SL::Config ();
my $config = SL::Config->new();

print STDOUT "Starting SL::Proxy server on port "
  . $config->sl_apache_listen . "\n";
print STDOUT "Loading modules...\n";

# status
if ( $config->sl_status ) {
    use Apache2::Status;
}

# Preload these modules during httpd startup, don't import any symbols
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

use SL::Config ();
use SL::DNS    ();
use SL::Static ();
use SL::Proxy  ();
use SL::Proxy::Cache ();
use SL::Proxy::Search::FixupHandler ();
use SL::Proxy::Search::TransHandler ();
use SL::Proxy::Search::PostReadRequestHandler ();

use URI 	();
use HTTP::Headers::Util ();

BEGIN {

    require 'utf8_heavy.pl';
    require 'unicore/PVA.pl';
    require 'unicore/Exact.pl';
    require 'unicore/Canonical.pl';
    require 'unicore/To/Fold.pl';
    require 'unicore/lib/gc_sc/SpacePer.pl';
}

our $iptables = '/sbin/iptables';
our $ebtables = '/sbin/ebtables';

print "flushing\n";
`$iptables -t nat -F`;
`$ebtables -t broute -F`;

# setup the firewall rules
`$iptables -t nat -A PREROUTING -i br0 -p tcp -m tcp --dport 8135 -j DNAT --to-destination :80`;

# grab google ips and setup the firewall
print "grabbing ips\n";
my @ips = SL::DNS->resolve({hostname => 'www.google.com'});

foreach my $ip (@ips) {

    print "setting ip $ip\n";
    `$ebtables -t broute -A BROUTING -p IPv4 -i eth1 --ip-dst $ip -j redirect --redirect-target ACCEPT`;

    `$iptables -t nat -A PREROUTING -d $ip -i br0 -p tcp -m tcp --dport 80 -j REDIRECT --to-ports 9999`;
}

print STDOUT "Startup.pl finished...\n";

1;
