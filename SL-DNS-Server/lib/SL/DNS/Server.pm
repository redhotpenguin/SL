package SL::DNS::Server;

use strict;
use warnings;

use base 'Danga::Socket';

use fields qw(query packet);


use Data::Dumper;
use IO::Socket::INET;
use Net::DNS;
use IO::AIO;

use constant DEBUG => 1;

sub new {
    my $class = shift;

    my $sock = IO::Socket::INET->new(
        LocalAddr => '127.0.0.1:53',

        #    LocalAddr => '192.168.1.201:53',
        Proto     => "udp",
        ReuseAddr => 1,
        Blocking  => 0,
            Type      => SOCK_DGRAM,
    ) || die $!;

    IO::Handle::blocking( $sock, 0 );

    my $accept_handler = sub {

      print "accept handler\n";
            my $csock = $sock->connect;
            return unless $csock;

            IO::Handle::blocking($csock, 0);

            my $client = SL::DNS::Connection->new($csock);
            $client->watch_read(1);
    };

    Danga::Socket->AddOtherFds(fileno($sock) => $accept_handler);

    my $self = fields::new($class);
    $self->SUPER::new($sock);

    $self->watch_read(1);

    return $self;
}

sub run {
    my $self = shift;

#    Danga::Socket->AddOtherFds( fileno( $self->{sock} ) => $self );

    Danga::Socket->AddOtherFds (IO::AIO::poll_fileno() =>
                                \&IO::AIO::poll_cb);


    Danga::Socket->EventLoop;
}

sub event_read {
    my SL::DNS::Server $self = shift;

    print "reading from " . $self->peer_ip_string . "...\n" if DEBUG;

    #$self->{sock}->recv( my $buf, &Net::DNS::PACKETSZ );
    my $buf = $self->read( &Net::DNS::PACKETSZ );

    print "buf $$buf\n";

    # nothing to read?
    return 1 if ( length($$buf) == 0 );

    $self->watch_read(0);

    my $query = Net::DNS::Packet->new( $buf );

    my $packet = Net::DNS::Packet->new;

    push @{ $packet->{question} }, $query->question;

    my $rr = Net::DNS::RR->new("foo.example.com.86400 A 10.0.2.3");

    $packet->header->id( $query->header->id );

    my $nscount = $packet->unique_push( update => $rr );

    my $data = $packet->data;

    $self->{packet} = $packet;

    $self->watch_write(1);

    return;

}

sub event_write {
    my SL::DNS::Server $self = shift;

    print "event write\n" if DEBUG;
    my $packet = $self->{packet};

#    print( "packet " . Dumper($packet) ) if DEBUG;

    use Data::Dumper;

  #  my $sf = __PACKAGE__->get_sock_ref;
#    print Dumper($self);

    print("data " . Dumper($self->peer_ip_string) . "\n");
    $self->write( $packet->data );
   # $self->write( sub { return $packet->data } );
#    $self->{sock}->send("FOOOO");


    $self->watch_read(1);
    $self->watch_write(0);
    return 1;
}

1;
