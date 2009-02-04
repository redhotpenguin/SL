#!/usr/bin/microperl;

# SET THIS IP AFTER ENTERING THE MAC ADDRESS ON THE OPEN-MESH.COM DASHBOARD
$wan_gateway='5.73.61.90';

# get the free memory
my ($mem) = `/usr/bin/free` =~ m/Mem:\s+(\d+)/;

# get the mac address
my $ifconfig = `ifconfig`;
my ($macaddr) = $ifconfig =~ m/(\w{2}\:\w{2}\:\w{2}\:\w{2}\:\w{2}\:\w{2})/;
# warn("Macaddr is $macaddr");

# set some arbitrary other data
my $data = "ip=$wan_gateway&mac=$macaddr&robin=1500&batman=0.5.6-r3&memfree=$mem";
$data .= "&ssid=argenta&pssid=-none-&users=0&kbup=0&kbdown=0&top_users=-none-";

# get the uptime, and extract the date components
my ($hours, $min, $sec, $days) = `/usr/bin/uptime`
    =~ m/(\d{2})\:(\d{2})\:(\d{2})\D+(\d+)\s/;

# hrm uptime is broken
my $uptime = sprintf("%0dd:%0dh:%02dm", $days, $hours, $min);

# gw-qual to make the outage bar green, 1 hop for gateway
$data .= "&uptime=$uptime&NTR=0&gateway=self&gw-qual=255&routes=-none-";
$data .= "&hops=1&RTT=0&nbs=0&nodes=0&rssi=20&rssi=20";

# hostname
my $hostname = 'checkin.open-mesh.com';

# build the url
my $str = "https://$hostname/checkin-batman.php?$data";

# log it for troubleshooting
# warn("url is $str");

# send stats to open-mesh
exec( "/usr/bin/curl",  "-k",  "$str");

