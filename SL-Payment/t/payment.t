#!/usr/bin/perl;

use strict;
use warnings;

use Test::More tests => 3;

my $pkg;

BEGIN {
    $pkg = 'SL::Payment';
    use_ok($pkg);
    can_ok($pkg, qw( plan paypal_button process ) );
}

my $button = $pkg->paypal_button( 'one',
   'http://www.silverliningnetworks.com/site/splash.html',
   'https://app.silverliningnetworks.com/sl/auth?mac=FF:FF:FF:FF:FF:FF',
   '1 Hour airCloud WiFi Network purchase',
   1,
);

ok($button);
