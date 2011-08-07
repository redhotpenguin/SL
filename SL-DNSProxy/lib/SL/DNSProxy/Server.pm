package SL::DNSProxy::Server;

use strict;
use warnings;

use IO::Socket;
use Danga::Socket;
use SL::DNSProxy::Client;

sub create {
    my $class = shift;

    my $sock = IO::Socket::INET->new(
        LocalAddr => '127.0.0.1:53',

        #            LocalAddr => '192.168.1.4:53',
        Proto     => "udp",
        ReuseAddr => 1,
        Blocking  => 0,
    ) || die $!;

    IO::Handle::blocking( $sock, 0 );

    my $client_handler = sub {

        print "client handler callback with fd " . fileno($sock) . "\n";
        print "asfds " . Dumper( Danga::Socket->OtherFds ) . "\n";

        my $client = SL::DNSProxy::Client->new($sock);

        #      $client->watch_read(1);
    };

    Danga::Socket->AddOtherFds( fileno($sock) => $client_handler );
    use Data::Dumper;
    print "sfds " . Dumper( Danga::Socket->OtherFds ) . "\n";
}

1;
