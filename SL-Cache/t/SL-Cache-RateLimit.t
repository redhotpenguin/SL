#!perl

use strict;
use warnings FATAL => 'all';

use Test::More tests => 5;

my $pkg;

BEGIN {
    $pkg = 'SL::Cache::RateLimit';
    use_ok($pkg);
}

can_ok( $pkg, qw(check_violation record_ad_serve) );

my $rl = $pkg->new;
$rl->{cache}->clear;

my $ip = '127.0.0.1';
my $ua = 'someuseragent';
my $ratelimit = 1;
{
    no strict 'refs';
    ${"$pkg\:\:RATE_LIMIT"} = $ratelimit;    # for testing
}

my $is_toofast = $rl->check_violation( $ip, $ua );
ok( !$is_toofast );

$rl->record_ad_serve( $ip, $ua );

$is_toofast = $rl->check_violation( $ip, $ua );
ok($is_toofast);
diag("sleeping $ratelimit seconds...");
sleep $ratelimit+1;

$is_toofast = $rl->check_violation( $ip, $ua );
ok( !$is_toofast );
