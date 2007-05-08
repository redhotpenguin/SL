#!perl -w

use strict;
use warnings;
use English;

=head1 NAME

 linksys_configure.pl

=head1 SYNOPSIS

 sets up a linksys box

 linksys_configure.pl --pass='rootpassword' --active=1;

 linksys_configure.pl --help

 linksys_configure.pl --man
 
=cut

use Getopt::Long;
use Pod::Usage;

# Config options
my $passwd;
my $active = 0;
my ($help, $man);

pod2usage(1) unless @ARGV;
GetOptions(
           'active=i' => \$active,
           'passwd=s' => \$passwd,
           'help'     => \$help,
           'man'      => \$man,
          )
  or pod2usage(2);

pod2usage(1) if $help;
pod2usage(-verbose => 2) if $man;

use Data::Dumper;

my $host = '192.168.1.1';
$|++;
use Net::Telnet ();
my $t = Net::Telnet->new(Timeout => 30,);
die unless $t;
print "==> TEST RUN, --active=$active <==\n\n";
#sleep 1;
$t->dump_log('/tmp/linksys');
print "opening host $host\n";
my $ok = $t->open($host);
die "Could not open remote host $host\n" unless $ok;

#$DB::single=1;
print STDERR "setting passwd...\n";
$t->errmode("return");
$t->cmd_remove_mode(1);
$t->cmd("passwd");# if $active;
print "last prompt: " . $t->last_prompt();
$t->waitfor('/Enter new password:\s$/i')
  or die "No password prompt: " . $t->lastline;
print STDERR "Set pass $ok, lastline: " . $t->lastline;
die "Could not set password\n" unless $ok;

$t->print($passwd);

$t->waitfor('/Re-enter new password/')
  or die "No password re-enter prompt: " . $t->lastline;
$t->print($passwd);

$t->waitfor('/changed/i')
  or die "Could not be changed to $passwd: " . $t->lastline;
print $t->lastline;

#print "password set to $passwd successfully\n" if $ok;

use FindBin;
my @ok;
my @conf_files =
  map { "$FindBin::Bin/../conf/linksys/etc/$_" }
  qw( banner dnsmasq.conf firewall.user);
die unless @conf_files;
foreach my $conf_file (@conf_files) {
    my ($rel_conf) = $conf_file =~ m{/([^/]+)$};
    my $rm_existing = "rm /etc/$rel_conf";
    @ok = $t->cmd($rm_existing) if $active;
    print "output from remove /etc/$rel_conf is " . Dumper(\@ok) . "\n";

    my $fh;
    open($fh, "<", $conf_file) or die "file $conf_file: $!";
    while (my $line = <$fh>) {
        chomp($line);
        my $write_new = "echo '$line' >> /etc/$rel_conf";
        $DB::single = 1;
        my $ok = $t->cmd($write_new) if $active;
        die "Error: writing_new $write_new, code $ok\n" unless $ok;
    }
    close($fh);
}
my $lan_ipaddr = '192.168.69.1';
my $wl_ssid    = 'free_wireless';

my %config = (
              lan_ipaddr => $lan_ipaddr,
              wl_ssid    => $wl_ssid
             );

foreach my $setting (keys %config) {
    print "applying setting $setting = " . $config{$setting} . "\n";
    my $set =
        "nvram set $setting="
      . $config{$setting}
      . "; sleep 1; nvram commit; nvram show $setting;";
    $DB::single = 1;
    @ok = $t->cmd($set) if $active;
    print 'output from set is ' . @ok . "\n";
}

my $remove_inits = <<RM;
rm /etc/init.d/S50telnet;
 sleep 1;
 rm /etc/init.d/S50dropbear; 
sleep 1; 
ls /etc/init.d
RM

#@ok = $t->cmd($remove_inits) if $active;
print 'output from remove_inits is ' . @ok . "\n";

{
    print "rebooting if not $active...\n";
    my $reboot = "reboot";

    @ok = $t->cmd($reboot) if $active;
    print 'output from reboot is ' . @ok . "\n";

    print "exiting router ...\n";
    $t->cmd(String => "exit", Errmode => "return");
    print "closing connection...\n";
    $ok = $t->close();
    print "Initialization complete commander\n";
    exit(0);
}

1;

__END__

=head1 DESCRIPTION

[DESCRIPTION]

=head1 OPTIONS

=over 4

=item B<opt1>

The first option

=item B<opt2>

The second option

=back

=head1 TODO

=over 4

=item *

Todo #1

=back

=head1 BUGS

None yet

=head1 AUTHOR

[AUTHOR]

=cut

#===============================================================================
#
#         FILE:  linksys_configure.pl
#
#        USAGE:  ./linksys_configure.pl 
#
#  DESCRIPTION:  
#
#      OPTIONS:  ---
# REQUIREMENTS:  ---
#         BUGS:  ---
#        NOTES:  ---
#       AUTHOR:   (), <>
#      COMPANY:  
#      VERSION:  1.0
#      CREATED:  05/06/06 03:36:40 PDT
#     REVISION:  ---
#===============================================================================