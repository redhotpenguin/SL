package SL::DNS;

use strict;
use warnings;

use Net::DNS;

use constant NAMESERVER => '208.67.222.222';

our $resolver;

BEGIN {
    $resolver = Net::DNS::Resolver->new;
}

sub resolve {
    my ( $class, $hostname, $nameserver ) = @_;

    $nameserver ||= NAMESERVER;

    $resolver->nameserver($nameserver);

    my $ip;
    my $query = $resolver->query($hostname);

    die $resolver->errorstring unless $query;

    foreach my $rr ( $query->answer ) {
        next unless $rr->type eq "A";
        $ip = $rr->address;
        last;
    }

    return $ip;
}

1;
