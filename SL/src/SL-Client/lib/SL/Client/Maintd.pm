package SL::Client::Maintd;

use strict;
use warnings;

my $DATA_CENTER = 'app.redhotpenguin.com';
my $DC_PORT = 30681;

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
        return \( dns => "DNS query for $DATA_CENTER resolved to " .
            Data::Dumper::Dumper($query->answer) . " \n" );
    } elsif ( !$query ) {
        return \( dns => "DNS query for $DATA_CENTER FAILED\n" );
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
    my ($ret, $duration, $ip) = $ping->ping( $DATA_CENTER,5.5 );

    if ( $ret ) {
        my $return = 
            sprintf(
                "$DATA_CENTER [ip:$ip] is alive (packet return time: %.f ms)\n",
                    1000 * $duration);
        return \( ping => $return );
    } elsif ( !$ret ) {
        return \( ping => "Ping to $DATA_CENTER FAILED\n" );
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
    my $restart = `ssh -2 -f -N -R $DC_PORT:localhost:20022 fred\@$DATA_CENTER`;
    print STDERR "Restart status: $restart";
    return $restart;
}

1;
