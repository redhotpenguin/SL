#!/usr/bin/env perl

use strict;
use warnings;

use HTTP::Request;
use LWP::UserAgent;
use Sys::Hostname;

my $user = 'fred';
my $port = '9022';
my $host = 'app.redhotpenguin.com';
my %servers = ( herbert => { tunnel_ent_port => 30681 },
		herbert2 => { tunnel_ent_port => 30682 } );

my $server = hostname();
my $tunnel_ent_port = $servers{$server}->{'tunnel_ent_port'};
my $colo_tunnel_port = 20022;
my $url = "http://$host/cgi-bin/tunnel.cgi?host=$server";

my $ua = LWP::UserAgent->new;
my $req = HTTP::Request->new( 'GET', $url );
my $response = $ua->request( $req);

if ( $response->content eq '0' ) {
    # Tunnel down
    print "ALERT!  Tunnel down\n";
    # Check to see if the process is running
    my $proc = `ps aux | grep 'ssh -p $port -2 -f -N'`;
    if ( $proc && ( ! $proc =~ m/^grep/ ) ) {
        print "Existing tunnel process found: $proc\n";
        print "Killing it\n";
        my ($user, $pid) = $proc =~ m/^(\w+)\s+(\d+)/;
        my $procs_killed = kill 9, $pid;
        print "Killed $procs_killed for pid $pid\n";
    }
    # Restart the tunnel
    print "Starting tunnel\n";
    use IPC::Run3;
    my ( $in, $out, $err);
    my @cmd = ("ssh", "-p $port", "-2", "-f", "-N", 
    	"-R $tunnel_ent_port:localhost:$colo_tunnel_port",  "$user\@$host");
    run3( \@cmd, \$in, \$out, \$err);
    print "Tunnel started\n";
} elsif ( $response->content eq '1' ) {
    #print "Tunnel up\n";
}
