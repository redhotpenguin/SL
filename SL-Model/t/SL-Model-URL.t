use strict;
use warnings FATAL => 'all';

use Test::More tests => 7;

BEGIN {
    use_ok('SL::Model::URL');
}

can_ok('SL::Model::URL', qw(not_html ping_blacklist_regex generate_blacklist_regex get_blacklisted_urls));

use Time::HiRes qw(tv_interval gettimeofday);

# initialize the blacklist regex
my $start = [gettimeofday];
my $blacklist_regex = SL::Model::URL->generate_blacklist_regex;
my $interval = tv_interval($start, [gettimeofday]);
diag("Initial blacklist creation took $interval");

$start = [gettimeofday];
my $ping = SL::Model::URL->ping_blacklist_regex;
$interval = tv_interval($start, [gettimeofday]);

diag("ping_blacklist_regex was $interval");
cmp_ok($interval, '<', 0.05, 'Blacklist ping in less than 50 ms');
ok(!$ping, 'ping returned no change');

my @urls = SL::Model::URL->get_blacklisted_urls;

diag("Test that all urls match the blacklist regex");
my $all_matched = grep { $_ =~ m/$blacklist_regex/ } @urls;
cmp_ok($all_matched, '==', scalar(@urls), "$all_matched urls matched ok");

diag("benchmark match against a regex");
$start = [gettimeofday];
my ($match) = $urls[0] =~ m{$blacklist_regex};
$interval = tv_interval($start, [gettimeofday]);

diag("match against computed regex took $interval");
cmp_ok($interval, '<', 0.02, 'match in less than 20 ms');
cmp_ok($match, '==', 1, 'url matched regex');

1;
