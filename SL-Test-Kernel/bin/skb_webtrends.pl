#!/usr/bin/perl

use strict;
use warnings;

my $hostip = shift or die "$0 10.2.0.1 [8135]\n";

my $port = shift || 80;

use Time::HiRes qw(gettimeofday tv_interval);
use SL::Client::HTTP;

my $start = [gettimeofday];

$DB::single = 1;

my $url = 'http://wwww.googlee.com/mail/channel/bind?at=xn3j2v9hgz1alnhx0otznbju9f8xs7&VER=6&it=12&SID=C0430DDD724F9434&RID=48959&zx=klug2zrrl4rd&t=1';

my $url = 'http://wt.o.nytimes.com/dcsaon9rw0000008ifmgqtaeo_2f9c/dcs.gif?&dcsdat=1257826652293&dcssip=www.nytimes.com&dcsuri=/2009/11/10/science/10patch.html&dcsqry=%3Fhp&dcsref=http://www.nytimes.com/&WT.co_f=2dcf3d71482c5615cee1247783658895&WT.vt_sid=2dcf3d71482c5615cee1247783658895.1257826323603&WT.tz=-6&WT.bh=22&WT.ul=en-US&WT.cd=24&WT.sr=1280x800&WT.jo=Yes&WT.ti=Researchers%20Explore%20Growing%20Ocean%20Garbage%20Patches%20-%20NYTimes.com&WT.js=Yes&WT.jv=1.7&WT.ct=unknown&WT.bs=1280x607&WT.fi=Yes&WT.fv=10.0&WT.tv=1.0.7&WT.dl=0&WT.es=www.nytimes.com/2009/11/10/science/10patch.html&WT.cg_n=Science&WT.z_gpt=Article&WT.cre=The%20New%20York%20Times&WT.z_nyts=20vMgabF/f2RqW0MykKhAfTgPyvM01.EZTs7Br4iYu3CbFcrH3fvogQ6WhyOe3EQ3cjV.wA22sJ1yXFFjVDJbWRsSnzwtIA5P11455GEJ6H43JascDDiYpbN/JwtJDXXeRDguA6xzmNSPt2GK6uHnGUK.4bOwt.3RQwgcZiAed6Mo0&WT.z_nytd=101.HeD0P0n0gCAI0a0K@c5c3011/af663df9&WT.z_rmid=2637e37a126d4a5f65cb6a57&WT.z_ref=nytimes.com&WT.dcsvid=52761254&WT.rv=1&WT.z_gpst=News&WT.z_hdl=Afloat%20in%20the%20Ocean,%20Expanding%20Islands%20of%20Trash&WT.z_aid=1247465585261&WT.z_pud=20091110&WT.z_put=web&WT.z.gsg=web&WT.z_pua=free&WT.z_clmst=LINDSEY%20HOSHAW&WT.z_puv=Normal&WT.z_pudr=Tomorrow&WT.z_pyr=2009&WT.mc_ev=&WT.vt_f_tlv=&WT.vt_f_tlh=1257826630&WT.vt_f_d=&WT.vt_f_s=&WT.vt_f_a=&WT.vt_f=';


my	@headers = (
'User-Agent', 'Mozilla/5.0 (Macintosh; U; Intel Mac OS X; en-US; rv:1.8.1.14) Gecko/20080404 Firefox/2.0.0.14',
'Accept', 'text/xml,application/xml,application/xhtml+xml,text/html;q=0.9,text/plain;q=0.8,image/png,*/*;q=0.5',
'Accept-Language', 'en-us,en;q=0.5',
'Accept-Encoding',  'gzip,deflate',
'Accept-Charset', 'ISO-8859-1,utf-8;q=0.7,*;q=0.7',
'Referer', 'http://mail.google.com/mail/?ui=2&view=js&name=js&ids=qk1v6dmibzrk',
'Cookie', 'ACOOKIE=C8ctADcxLjEzOS4xNjYuNjItMzc4MzQyOTA0MC4zMDA0MDUxMAAAAAAAAAAEAAAA+r0AAEIS+UpCEvlKmLwAAMIN+UrCDflKEb4AAATK+UoEyvlK+70AAKUk+UqlJPlKAQAAAHhHAAAEyvlKBMr5SgAAAAA-; RMID=00c3216850f94af8ee7594c7; up=9BA4bk1dOkWA04Bi; zFN=9BAA09B0A10900A01; zFD=9BAA09B0A10900A01; WT_FPC=id=71.139.166.62-3783429040.30040510:lv=1257894991505:ss=1257894963898; TID=00g3iga15fhrlq; TData=; rsi_segs=H07707_10599|H07707_10193|H07707_10194|H07707_10195|H07707_10196|H07707_10197|H07707_10387; NYT_GR=4af9cec5-ttFFywrGbv+OsFJJ+bsW9A; NYT-S=20ydZA6I/jzO/0fNeT8z9qNMtNAQCb1kl9uVjRKqCYjRo9g0mzV565WFC7s2t0bP8R9QLrilpYYgw74hwCYxQr/VlUETbX8BVMUNNqHfv6IAbYYcMIMZlZfVDrkX0DN3tX4DEBoIIK9uXMnfLn/q18bSqWNRPsJEuoaBnZz5k0i5w0; NYT-Pref=hppznw|0^creator|NYTD.Cookies; adxcs=-|s*151ff=0:4|s*1ca92=0:5|s*1ca93=0:3; __utma=69104142.318780334.1257841823.1257841823.1257841823.1; __utmc=69104142; __utmz=69104142.1257841829.1.1.utmcsr=reddit.com|utmccn=(referral)|utmcmd=referral|utmcct=/; ups=9BAKGv1eOkWA05Gd; nyt-d=101.42Y000000NAI00001w8JK00MOoGf0T3NzO@db4db6c7/4355030f; NYT_W2=New%20YorkNYUS|ChicagoILUS|London--UK|Los%20AngelesCAUS|San%20FranciscoCAUS|Tokyo--JP|',
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

