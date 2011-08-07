package SL::DNSProxy::Client;

use strict;
use warnings;

use base qw(Danga::Socket);
use Data::Dumper;

use fields qw(query ssock);

use constant DEBUG => 1;

use Net::DNS;

sub new {
    my ( $class, $sock ) = @_;

    print "making new client object\n";

    my $self = fields::new($class);

    print "socket fd is " . fileno($sock) . "\n";

    $self->SUPER::new($sock);
    $self->watch_read(1);
    return $self;

}

sub event_read {
    my SL::DNSProxy::Client $self = shift;

    print "client event read\n";
    print "fds " . Dumper( $self->OtherFds ) . "\n";
    print Dumper( $self->sock );

    if ( !$self->{query} ) {
        my $buf = $self->read(&Net::DNS::PACKETSZ);

        return 1 if ( length($buf) == 0 );

        print "buf is " . Dumper($buf) . "\n";

        $self->watch_read(0);

        my $query = Net::DNS::Packet->new($buf);

        $self->{query} = $query;

        warn("data read: ");    # . Dumper($query) ) if DEBUG;

    }

    $self->watch_write(1);

    # $self->write("foo.example.com.86400 A 10.0.2.3");

    #  $self->watch_read(1);

    return;
}

sub event_write {
    my SL::DNSProxy::Client $self = shift;

    #  print "event write\n";
    print "query for write is " . Dumper( $self->{query} . "\n" );

    my $packet = Net::DNS::Packet->new;

    push @{ $packet->{question} }, $self->{query}->question;

    my $rr = Net::DNS::RR->new("foo.example.com.86400 A 10.0.2.3");

    $packet->header->id( $self->{query}->header->id );

    my $nscount = $packet->unique_push( update => $rr );

    print Dumper( $packet->data ) if DEBUG;

    $self->sock->write( $packet->data );

    $self->close;

    #  $self->write("event write write\n");

    # $self->close;

    $self->watch_write(0);
    $self->watch_read(1);

    return 0;
}
1;
