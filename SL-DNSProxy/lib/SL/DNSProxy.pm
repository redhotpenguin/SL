 package SL::DNSProxy;

use strict;
use warnings;

our $VERSION = 0.01;

use Danga::Socket;
use SL::DNSProxy::Server;
use IO::AIO;

use constant DEBUG => 1;

sub run {
  my $class = shift;

  SL::DNSProxy::Server->create;

  Danga::Socket->AddOtherFds (IO::AIO::poll_fileno() =>
                              \&IO::AIO::poll_cb);

  Danga::Socket->EventLoop();
}


1;

sub event_read {
    my SL::DNSProxy $self = shift;

    DEBUG && warn "entering event_read\n";

    if ( !$self->{query} ) {

        $self->{sock}->recv( my $buf, &Net::DNS::PACKETSZ );

        return 1 if ( length($buf) == 0 );

        $self->watch_read(0);
        my $query = Net::DNS::Packet->new( \$buf );

        $self->{query} = $query;

        warn( "data read: " . Dumper($query) ) if DEBUG;

        print "query read, run the lookup\n";
    }

    if ( !$self->{paradns} ) {

        my $paradns = ParaDNS->new(
            callback => sub {

                print "Got result $_[0] for query $_[1]\n" if DEBUG;
                push @{ $self->{results} }, { $_[0] => $_[1] };
                $self->watch_write(1);

            },
            host => $self->{query}->{question}->[0]->qname,
        );

        $self->{paradns} = $paradns;
        return;
    }

    unless ( @{ $self->{results} } ) {
        print( "waiting for paradns to finish " . $self->{wait_cycles} . "\n" );
        $self->{wait_cycles}++;

        return;
    }


    print( "got results " . Dumper( $self->{results} ) );

    my $packet = Net::DNS::Packet->new;

    push @{ $packet->{question} }, $self->{query}->question;

    my $rr = Net::DNS::RR->new("foo.example.com.86400 A 10.0.2.3");

    $packet->header->id( $self->{query}->header->id );

    my $nscount = $packet->unique_push( update => $rr );

    print Dumper($packet) if DEBUG;

    $self->write( $packet->data );

    #    $self->{sock}->send( $packet->data );

    print "results: " . Dumper( $self->{results} ) if DEBUG;

    return;
}
=cut
sub event_write {
    my SL::Proxy::DNS $self = shift;

    DEBUG && warn "entering event_write\n";

    if ( $self->{results}->[0] ) {
        warn( "we have some results = " . Dumper( $self->{results} ) );

        my $packet = Net::DNS::Packet->new;

        push @{ $packet->{question} }, $self->{query}->question;

        my $rr = Net::DNS::RR->new("foo.example.com.86400 A 10.0.2.3");

        $packet->header->id( $self->{query}->header->id );

        my $nscount = $packet->unique_push( update => $rr );

        print Dumper($packet) if DEBUG;

        $self->write( $packet->data );

        $self->watch_write(0);
        $self->watch_read(1);

        return 0;
    }

    return;

}
=cut

1;
