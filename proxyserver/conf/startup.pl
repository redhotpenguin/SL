#!/usr/bin/env perl

use strict;
use warnings;

# make sure we are in a sane environment.
$ENV{MOD_PERL} or die "GATEWAY_INTERFACE not Perl!";

use lib $ENV{SL_ROOT} . '/proxyserver/lib';

# Preload these modules during httpd startup, don't import any symbols
use Apache2::Connection ();
use Apache2::ConnectionUtil ();
use Apache2::Log        ();
use Apache2::Request    ();
use Apache2::RequestIO  ();
use Apache2::RequestRec ();
use Apache2::RequestUtil();
use Apache2::ServerRec  ();
use Apache2::ServerUtil ();
use Apache2::SubRequest ();
use Data::Dumper        ();
use Bundle::LWP         ();
use HTTP::Headers       ();
use HTTP::Request       ();
use HTTP::Response      ();
use SL::Model::Ad       ();
use SL::CS::Model       ();
use SL::Apache          ();
use SL::Apache::Reg     ();
use SL::Apache::PerlAccessHandler  ();
use SL::Apache::PerlTransHandler   ();
use SL::Cache           ();
use SL::UserAgent       ();
use SL::Util            ();
use DBI					();
1;
