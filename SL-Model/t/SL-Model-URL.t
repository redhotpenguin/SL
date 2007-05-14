use strict;
use warnings FATAL => 'all';

use Test::More tests => 6;

BEGIN {
    use_ok('SL::Model::URL');
}

can_ok('SL::Model::URL', qw(not_html blacklist_regex get_blacklisted_urls));

use Time::HiRes qw(tv_interval gettimeofday);

# initialize the blacklist regex
my $start = [gettimeofday];
my $blacklist_regex = SL::Model::URL->blacklist_regex;
my $interval = tv_interval($start, [gettimeofday]);
diag("Initial blacklist creation took $interval");

$start = [gettimeofday];
$blacklist_regex = SL::Model::URL->blacklist_regex;
$interval = tv_interval($start, [gettimeofday]);

diag("Cached blacklist creation time was $interval");
cmp_ok($interval, '<', 0.02, 'Blacklist recomputed in less than 20 ms');

my @urls = SL::Model::URL->get_blacklisted_urls;

diag("Test that all urls match the blacklist regex");
my $all_matched = grep { $_ =~ m/$blacklist_regex/ } @urls;
cmp_ok($all_matched, '==', scalar(@urls), "$all_matched urls matched ok");

diag("benchmark match against a regex");
$start = [gettimeofday];
$blacklist_regex = SL::Model::URL->blacklist_regex;
my ($match) = $urls[0] =~ m{$blacklist_regex};
$interval = tv_interval($start, [gettimeofday]);

cmp_ok($match, '==', 1, 'url matched regex');
cmp_ok($interval, '<', 0.02, 'blacklist matched in less than 20 ms');

1;
