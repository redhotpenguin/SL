package SL::Maintd;

use strict;
use warnings;

my $data_center = 'app.redhotpenguin.com';

sub new {
    my $class = shift;
    my $self = {};
    return bless $self, $class;
}

sub ip {
    my $self = shift;

    my $ifconfig = `/sbin/ifconfig`;
    my ($int, $link_encap, $mac, $ip) = $ifconfig =~ m/^(eth[0-1])\s+
        Link\sencap:(\w+)\s+HWaddr\s+(\S+)\s+
        inet\saddr:(\S+)/xms;

    my %return = (
            interface => $int, 
              ip => $ip,
              link_encap => $link_encap,
              mac        => $mac
          );
    return \%return;
}

sub uptime {
    my $self = shift;

    my $uptime = `uptime`;
    my %return = ( uptime => $uptime );
    return \%return;
}

sub dns {
    my $self = shift;
    require Net::DNS;
    my $res = Net::DNS::Resolver->new;
    my $query = $res->search("app.redhotpenguin.com");

    if ( $query ) {
        require Data::Dumper;
        return \( dns => "DNS query for $data_center resolved to " .
            Data::Dumper::Dumper($query->answer) . " \n" );
    } elsif ( !$query ) {
        return \( dns => "DNS query for $data_center FAILED\n" );
    }
}

sub ping {
    my $self = shift;
    require Net::Ping;
    my $ping = Net::Ping->new();
    {
        require Time::HiRes;
        $ping->hires();
    }
    my ($ret, $duration, $ip) = $ping->ping( $data_center,5.5 );

    if ( $ret ) {
        my $return = 
            sprintf(
                "$data_center [ip:$ip] is alive (packet return time: %.f ms)\n",
                    1000 * $duration);
        return \( ping => $return );
    } elsif ( !$ret ) {
        return \( ping => "Ping to $data_center FAILED\n" );
    }
}

sub tunnel {
    my $self = shift;

    my $tunnel_status = `ps aux | grep "ssh -2 -f -N -R"`;
    if ( $tunnel_status ) {
        return \( tunnel => "Tunnel online, process dump:  $tunnel_status ");
    }
    elsif( !$tunnel_status ) {
        return \( tunnel => "SSH Tunnel INOPERATIVE!" );
    }
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
