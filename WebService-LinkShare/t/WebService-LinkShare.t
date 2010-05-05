#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 5;

BEGIN {
    use_ok('WebService::LinkShare');
    can_ok('WebService::LinkShare', qw( new targeted_merchandise ));
};

eval { WebService::LinkShare->new };
ok($@, 'exception thrown');

my $tok_n = '4e5c9767680b23d7965887f50f25a6ff17ddc1fcb1bc2f6df7cf8c493aead77c';

my $linkshare = WebService::LinkShare->new({ token => $tok_n });

isa_ok($linkshare, 'WebService::LinkShare');

diag('we need some pet meds');

my $mid = 2101; # 1-800-pet-meds

my $res = $linkshare->targeted_merchandise({ advertiser_mid => $mid });
isa_ok($res, 'HASH');

=cut
use Data::Dumper;
warn("res is " . Dumper($res));
=cut