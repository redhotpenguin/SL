package SL::Maintd;

use strict;
use warnings;

my $data_center = '192.168.2.6';

sub new {
    my $class = shift;
    my $self = {};
    return bless $self, $class;
}

sub tunnel {
    my $self = shift;

    my $tunnel_status = `ps aux | grep "ssh -2 -f -N -R"`;
    my %status;
    if ( $tunnel_status ) {
        $status{'process'} = $tunnel_status;
    }
    return \%status;
}

sub tunnel_restart {
    my $self = shift;

    if ( keys %{ $self->tunnel } )  {
        print STDERR "Existing tunnel process found, killing it\n";

    }
    my $restart = `ssh -2 -f -N -R 30681:localhost:20022 fred\@$data_center`;
    print STDERR "Restart status: $restart";
    return $restart;
}

1;
