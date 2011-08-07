package SL::Proxy::DNS;

use strict;
use warnings;

our $VERSION = 0.01;

use Data::Dumper;
use Net::DNS;
use Net::DNS::Packet;
use Net::DNS::RR;
use ParaDNS;
use Danga::Socket;
use base 'Danga::Socket';

use fields qw(query results);

use constant DEBUG         => 1;
use constant VERBOSE_DEBUG => 0;

sub new {
    my ( $class, $sock ) = @_;

    #warn("sock to new is $sock");
    my $self = fields::new($class);
    $self->SUPER::new($sock);
    $self->watch_read(1);
    $self->{results} = [];

    return $self;
}

sub event_read {
    my SL::Proxy::DNS $self = shift;

    DEBUG && warn "entering event_read\n";

    $self->{sock}->recv( my $buf, &Net::DNS::PACKETSZ );

    return 1 if ( length($buf) == 0 );

    $self->watch_read(0);
    my $query = Net::DNS::Packet->new( \$buf );

    warn( "data read: " . Dumper($query) ) if VERBOSE_DEBUG;

    my @q    = $query->question;
    my $name = $q[0]->qname;
    warn "query for " . Dumper($name) . "\n" if DEBUG;

#    $self->watch_write(1);
          $self->watch_read(1);
    ParaDNS->new(
        callback => sub {

            print "Got result $_[0] for query $_[1]\n" if DEBUG;
            push @{ $self->{results} }, { $_[0] => $_[1] };
        },
        host => $name,
    );

    my $packet = Net::DNS::Packet->new;

    push @{ $packet->{question} }, $query->question;

    my $rr = Net::DNS::RR->new("foo.example.com.86400 A 10.0.2.3");

    $packet->header->id( $query->header->id );

    my $nscount = $packet->unique_push( update => $rr );

    print Dumper($packet) if VERBOSE_DEBUG;

    $self->write( $packet->data );

#    $self->{sock}->send( $packet->data );

    print "results: " . Dumper( $self->{results} ) if DEBUG;

    return 1;

}

sub event_write {
    my SL::Proxy::DNS $self = shift;

    DEBUG && warn "entering event_write\n";

    $self->watch_write(0);
    return;
}

1;
