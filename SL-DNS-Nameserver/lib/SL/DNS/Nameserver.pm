package SL::DNS::Nameserver;

use 5.014001;
use strict;
use warnings;

our $VERSION = 0.01;

use base 'Net::DNS::Nameserver';

sub new {
    my ( $class, $args ) = @_;

    # default to development settings
    my $port    = $args->{port}    || '53535';
    my $ip      = $args->{ip}      || '127.0.0.1';
    my $verbose = $args->{verbose} || 1;

    my $ns = $class->SUPER::new(
        LocalAddr    => $ip,
        LocalPort    => $port,
        Verbose      => $verbose,
        ReplyHandler => \&reply_handler,
    );

    return $ns;
}

sub run {
    my $self = shift;
    $self->main_loop;
}

sub reply_handler {
    my ( $qname, $qclass, $qtype, $peerhost, $query, $conn ) = @_;

    my ( $rcode, @ans, @auth, @add );

    print "Received query from $peerhost to " . $conn->{"sockhost"} . "\n";
    $query->print;

    if ( $qtype eq "A" && $qname eq "foo.example.com" ) {

        my ( $ttl, $rdata ) = ( 3600, "10.1.2.3" );
        push @ans, Net::DNS::RR->new("$qname $ttl $qclass $qtype $rdata");
        $rcode = "NOERROR";

    }
    elsif ( $qname eq "foo.example.com" ) {
        $rcode = "NOERROR";

    }
    else {
        $rcode = "NXDOMAIN";
    }

    # mark the answer as authoritive (by setting the 'aa' flag
    return ( $rcode, \@ans, \@auth, \@add, { aa => 1 } );
}

1;
__END__

=head1 NAME

SL-DNS-Nameserver - Silver Lining Networks select based nameserver

=head1 SYNOPSIS

  use SL::DNS::Nameserver;

  my $ns = SL::DNS::Nameserver->new;

  $ns->run;

=head1 DESCRIPTION

SLN select based DNS server.

=head2 EXPORT

None by default.



=head1 SEE ALSO

Net::DNS

=head1 AUTHOR

Fred Moyer, E<lt>fred@slwifi.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2011 by Silver Lining Networks

This is proprietary software, you may not redistribute.

=cut
