#!/usr/bin/microperl

# enable these for testing
#use strict;
#use warnings;

my $file = 'firewall.user.new';
my $url = "http://www.redhotpenguin.com/sl/$file";
chdir('/etc');
my $grab = `wget $url`;

if (-e "/etc/$file") {
    print "$file retrieved ok\n";
    my $mv = `mv /etc/$file /etc/firewall.user`;
    print "Moved:  $mv\n";
} else {
    print "couldn't retrieve $url\n";
}

1;
