#!/usr/bin/perl

use strict;
use warnings;

my $hostip = shift or die "$0 10.2.0.1 [8135]\n";

my $port = shift || 80;

use Time::HiRes qw(gettimeofday tv_interval);
use SL::Client::HTTP;

my $start = [gettimeofday];

$DB::single = 1;

my $url = 'http://www.google.com/mail/channel/bind?at=xn3j2v9hgz1alnhx0otznbju9f8xs7&VER=6&it=12&SID=C0430DDD724F9434&RID=48959&zx=klug2zrrl4rd&t=1';

my	@headers = (
'X-SLR', 'zzzzzzzz|0016b6493d60',
'User-Agent', 'Mozilla/5.0 (Macintosh; U; Intel Mac OS X; en-US; rv:1.8.1.14) Gecko/20080404 Firefox/2.0.0.14',
'Accept', 'text/xml,application/xml,application/xhtml+xml,text/html;q=0.9,text/plain;q=0.8,image/png,*/*;q=0.5',
'Accept-Language', 'en-us,en;q=0.5',
'Accept-Encoding',  'gzip,deflate',
'Accept-Charset', 'ISO-8859-1,utf-8;q=0.7,*;q=0.7',
'Referer', 'http://mail.google.com/mail/?ui=2&view=js&name=js&ids=qk1v6dmibzrk',
'Pragma', 'no-cache',
'Cache-Control', 'no-cache',
);



my $response = SL::Client::HTTP->get(
                                     url      => $url,
                                     host     => $hostip,
                                     port     => $port,
                                     headers  => \@headers,
                                    );

my $end = tv_interval($start, [gettimeofday]);

use Data::Dumper;

print Dumper($response); #if $verbose;

print sprintf("\nTime: %s\n", $end);

