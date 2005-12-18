#!/usr/bin/env perl

use strict;
use warnings;

# make sure we are in a sane environment.
$ENV{MOD_PERL} or die "GATEWAY_INTERFACE not Perl!";

use lib '/home/fred/dev/sl/trunk/lib';

# Preload these modules during httpd startup, don't import any symbols
use Apache2::Log        ();
use Apache2::Request    ();
use Apache2::RequestIO  ();
use Apache2::RequestRec ();
use Apache2::RequestUtil();
use Apache2::ServerRec  ();
use Apache2::ServerUtil ();
use Data::Dumper        ();
use HTTP::Headers       ();
use HTTP::Request       ();
use HTTP::Response                  ();
use LWP::UserAgent                  ();
use SL::Ad                          ();
use SL::Apache                      ();
use SL::Apache::PerlTransHandler    ();
use SL::Cache                       ();
use SL::UserAgent                   ();
use SL::Util                        ();

1;
