#!/usr/bin/microperl

=head1 COPYRIGHT

Copyright Silver Lining Networks

This program is Free Software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=head1 AUTHOR

Fred Moyer <fred@redhotpenguin.com>

=head1 DESCRIPTION

This program polls the OLSR text module and parses the output.
It writes out a number of files for compatibility with the 
ROBIN firmware.

=cut


my $Verbose_Debug = 0;
my $Debug = 0;

my $olsrd_table = `echo "/" | nc 127.0.0.1 8090`;

chomp($olsrd_table);

print "table is $olsrd_table\n" if $Verbose_Debug;

# grab the different sections of olsrd output, split on newlines
my ($status, $links, $neighbors, $topo, $hna, $mid, $routes)
    = split(/\n\n/, $olsrd_table);

# check for non OK response
unless (substr($status, 0, 15) eq 'HTTP/1.0 200 OK') {
    die("err response from olsr: $status");
}

# first lets look in the hna table for internet gateways
print "hna table is $hna\n\n" if $Verbose_Debug;
my @gways;
foreach my $line (split(/\n/, $hna)) {

    next unless substr($line,0,9) eq '0.0.0.0/0';
    
    # we've found a gateway
    push @gways, (split(/\t/, $line))[1];
}

print "\nfound gateways: " . join(',', @gways) if $Debug;

# now take a look in the topology table and find routes
# from this node to the gateways
my $myip = `uci get network.mesh.ipaddr`;
chomp($myip);
print "\nmy ip is $myip\n" if $Debug;


print "topo table is $topo\n\n" if $Verbose_Debug;
my @routes;
foreach my $line (split(/\n/, $topo)) {

     my ($dest, $last_hop, $lq, $nlq, $cost) = split(/\t/, $line);

     # skip non self last hops
     next unless $last_hop eq $myip;

     # see if the destination is one of the internet gateways
     if (grep { $_ eq $dest } @gways) {

     	# found a valid route to the net
     	push @routes, [ $dest, $last_hop, $lq, $nlq, $cost ];
     }     

} 

# pick the least cost route
my ($best_route) = sort { $a->[4] <=> $a->[4] } @routes;

print "Best route found, " . join(",", @$best_route) . "\n" if $Debug;

my $qual = sprintf("%2.0f\n", $best_route->[2]*$best_route->[3]*255);

print $best_route->[0] . ' ' . $qual;
