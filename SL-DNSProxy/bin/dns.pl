#!/usr/bin/perl

use strict;
use warnings;

use SL::DNSProxy;

SL::DNSProxy->run;






=cut

use IO::Socket::INET;
use SL::Proxy::DNS;
use Danga::Socket;
use IO::AIO;


my $sock = IO::Socket::INET->new(
    LocalAddr => '127.0.0.1:53',
#    LocalAddr => '192.168.1.193:53',
    Proto     => "udp",
    ReuseAddr => 1,
    Blocking  => 0,
) || die $!;

IO::Handle::blocking($sock, 0);


print "created socket $sock\n";
#Danga::Socket->AddTimer(0, sub { SL::Proxy::DNS->new($sock) } );

Danga::Socket->AddOtherFds(
    fileno($sock) => sub { SL::Proxy::DNS->new($sock) }
);

Danga::Socket->AddOtherFds (IO::AIO::poll_fileno() =>
                           \&IO::AIO::poll_cb);

#Danga::Socket::AddTimer(0, sub {});


use Data::Dumper;
Danga::Socket->EventLoop;

warn "Clean Exit!\n";
exit 0;
