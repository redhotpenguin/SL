package SL::CP::IPTables;

use strict;
use warnings;

use Data::Dumper   qw(Dumper);

use SL::Config     ();
use LWP::UserAgent ();
use Crypt::SSLeay  ();
use URI::Escape    ();

use constant DEBUG => $ENV{SL_DEBUG} || 0;

our (
    $Config,                  $Iptables,   $Wan_if,
    %tables_chains,           $Lan_if,     $Auth_host,
    $Perlbal_port,            $Ad_proxy,
    $Mark_op,                 $Auth_url,   $Lease_file,
    $Gateway_ip,              $Wan_ip,     $Wan_mac,
);

BEGIN {
    $Config       = SL::Config->new;
    $Iptables     = $Config->sl_iptables || die 'oops';
    $Perlbal_port = $Config->sl_perlbal_port || die 'oops';

    # wan and lan interfaces
    $Wan_if  = $Config->sl_wan_if || die 'oops';
    $Lan_if  = $Config->sl_lan_if || die 'oops';

    ($Gateway_ip)  = `/sbin/ifconfig $Lan_if` =~ m/inet addr:(\S+)/;
    ($Wan_ip)      = `/sbin/ifconfig $Wan_if` =~ m/inet addr:(\S+)/;
    ($Wan_mac)     = `/sbin/ifconfig $Wan_if` =~ m/HWaddr\s(\S+)/;

    $Auth_host   = $Config->sl_auth_server     || die 'oops';
    $Auth_url    = $Config->sl_cp_auth_url     || die 'oops';
    $Ad_proxy    = $Config->sl_proxy           || die 'oops';
    $Mark_op     = $Config->sl_mark_op         || die 'oops';
    $Lease_file  = $Config->sl_dhcp_lease_file || die 'oops';

    %tables_chains = (
        filter => [qw( slAUT slAUTads slNET slRTR )],
        mangle => [qw( slBLK slINC slOUT slTRU )],
        nat    => [qw( slOUT slADS )],
    );

}

our $UA = LWP::UserAgent->new;
$UA->timeout(60);

our $Blocked_mark = '0x100';
our $Trusted_mark = '0x200';
our $Paid_mark    = '0x400';
our $Ads_mark     = '0x500';

sub load_allows {
    my ($class, $file) = @_;

    my $fh;
    open($fh, '<', $Config->sl_config . "/$file") or die $!;
    my $ct = do { local $/; <$fh> };
    close($fh) or die $!;

    my @lines = split(/\n/, $ct);
    @lines = grep { $_ =~ m/\S/ }
             grep { $_ !~ /#/ }   # skip comments
             grep { defined $_ } @lines; # skip undef

    return \@lines;
}

sub init_firewall {
    my $class = shift;

    `echo 1 > /proc/sys/net/ipv4/ip_forward`;

    # flush the existing firewall
    $class->clear_firewall();

    # create the chains
    foreach my $table ( sort keys %tables_chains ) {
        foreach my $chain ( @{ $tables_chains{$table} } ) {

            iptables("-t $table -N $chain");
        }
    }

    # walled garden exceptions
    my $hosts_allow = $class->load_allows('cp_hosts_allow.txt');
    my $sslhosts_allow = $class->load_allows('cp_sslhosts_allow.txt');
    my $accept = "slNET -d %s -p tcp -m tcp --dport %d -j ACCEPT";

    my $slout = "slOUT -d %s -p tcp -m tcp --dport %d -j ACCEPT";


    my $hosts_accept = join("\n", map { sprintf($accept, $_, 80) }
        @{$hosts_allow});

    my $sslhosts_accept = join("\n", map { sprintf($accept, $_, 443 ) }
        @{$sslhosts_allow} );

    my $hosts_slout = join("\n", map { sprintf($slout, $_, 80) }
        @{$hosts_allow});

    my $sslhosts_slout = join("\n", map { sprintf($slout, $_, 443 ) }
        @{$sslhosts_allow} );

    ##############################
    # add the filter default chains
    my $filters = <<"FILTERS";
INPUT -i $Lan_if -j slRTR

FORWARD -i $Lan_if -j slNET

slAUT --protocol tcp --source-port ! 25 -j ACCEPT

slAUTads -m state --state RELATED,ESTABLISHED -j ACCEPT
slAUTads -p tcp -m tcp --dport 22 -j ACCEPT 
slAUTads -p tcp -m tcp --dport 53 -j ACCEPT 
slAUTads -p udp -m udp --dport 53 -j ACCEPT 
slAUTads -p tcp -m tcp --dport 80 -j ACCEPT 
slAUTads -p tcp -m tcp --dport 110 -j ACCEPT 
slAUTads -p tcp -m tcp --dport 143 -j ACCEPT 
slAUTads -p tcp -m tcp --dport 443 -j ACCEPT 
slAUTads -p tcp -m tcp --dport 465 -j ACCEPT 
slAUTads -p udp -m udp --dport 500 -j ACCEPT 
slAUTads -p tcp -m tcp --dport 587 -j ACCEPT 
slAUTads -p tcp -m tcp --dport 993 -j ACCEPT 
slAUTads -p tcp -m tcp --dport 995 -j ACCEPT 
slAUTads -p tcp -m tcp --dport 1723 -j ACCEPT 
slAUTads -p udp -m udp --dport 1701 -j ACCEPT 
slAUTads -p tcp -m tcp --dport 3389 -j ACCEPT 
slAUTads -p tcp -m tcp --dport 5050 -j ACCEPT 
slAUTads -p tcp -m tcp --dport 5190 -j ACCEPT 
slAUTads -p tcp -m tcp --dport 5222 -j ACCEPT 
slAUTads -p tcp -m tcp --dport 5223 -j ACCEPT 
slAUTads -p tcp -m tcp --dport 8136 -j ACCEPT 

slNET -m mark --mark $Blocked_mark/0x700 -j DROP
slNET -m state --state INVALID -j DROP
slNET -p tcp -m tcp --tcp-flags SYN,RST SYN -j TCPMSS --clamp-mss-to-pmtu
slNET -m mark --mark $Trusted_mark/0x700 -j ACCEPT
slNET -m mark --mark $Paid_mark/0x700 -j slAUT
slNET -m mark --mark $Ads_mark/0x700 -j slAUTads
slNET -p tcp -m tcp --dport 53 -j ACCEPT
slNET -p udp -m udp --dport 53 -j ACCEPT
$hosts_accept
$sslhosts_accept

slRTR -m mark --mark $Blocked_mark/0x700 -j DROP
slRTR -m state --state INVALID -j DROP
slRTR -m state --state RELATED,ESTABLISHED -j ACCEPT
slRTR -p tcp -m tcp ! --tcp-option 2 --tcp-flags SYN SYN -j DROP
slRTR -p tcp -m tcp --dport $Perlbal_port -j ACCEPT
slRTR -m mark --mark $Trusted_mark/0x700 -j ACCEPT
slRTR -p tcp -m tcp --dport 22 -j ACCEPT
slRTR -p udp -m udp --dport 53 -j ACCEPT
slRTR -p tcp -m tcp --dport 53 -j ACCEPT
slRTR -p udp -m udp --dport 67 -j ACCEPT
slRTR -p tcp -m tcp --dport 8135 -j ACCEPT
slRTR -p tcp -m tcp --dport 20022 -j ACCEPT
slRTR -j REJECT --reject-with icmp-port-unreachable
FILTERS

    add_rules( 'filter', $filters );

    #############################
    # default mangle chains
    my $mangles = <<"MANGLES";
PREROUTING -i $Lan_if -j slOUT
PREROUTING -i $Lan_if -j slBLK
PREROUTING -i $Lan_if -j slTRU
POSTROUTING -o $Lan_if -j slINC
MANGLES

    add_rules( 'mangle', $mangles );

    #############################
    # default nat chains
    my $nats = <<"NATS";
PREROUTING -i $Lan_if -j slOUT
POSTROUTING -o $Wan_if -j MASQUERADE

slOUT -m mark --mark $Trusted_mark/0x700 -j ACCEPT
slOUT -m mark --mark $Paid_mark/0x700 -j ACCEPT
slOUT -p tcp -m tcp --dport 22 -j ACCEPT
slOUT -p tcp -m tcp --dport 53 -j ACCEPT
slOUT -p udp -m udp --dport 53 -j ACCEPT
slOUT -p tcp -m tcp --dport 20022 -j ACCEPT
$hosts_slout
$sslhosts_slout
slOUT -p tcp -m tcp --dport 80 -j DNAT --to-destination $Gateway_ip:$Perlbal_port
slOUT -j ACCEPT

NATS

    add_rules( 'nat', $nats );

    # setup the search page chain
    if ($Config->sl_search eq 'On') {

        my $hosts_allow = $class->load_allows('search_hosts.txt');

        my $target = ($Config->sl_adbar eq 'On') ? 'slADS' : 'ACCEPT';
        iptables("-t nat -I slOUT 3 -m mark --mark $Ads_mark/0x700 -j $target");
        foreach my $hostname ( @{$hosts_allow} ) {

            my $rule = "-t nat -I slOUT 3 -m mark --mark $Ads_mark/0x700 -d %s -i $Lan_if -p tcp -m tcp --dport 80 -j REDIRECT --to-ports $Perlbal_port";
            iptables(sprintf($rule, $hostname));
        }

    }

    if ($Config->sl_adbar eq 'On') {

        my $nat_ads = <<"NATS";
slADS -p udp -j ACCEPT
slADS -p tcp -m tcp --dport 443 -j ACCEPT
slADS -p tcp -m tcp --dport 8135 -j DNAT --to :80
slADS -p tcp -m tcp ! --dport 80 -j ACCEPT
slADS -p tcp -m tcp --dport 80 -j DNAT --to-destination $Ad_proxy
slADS -j ACCEPT
NATS

        add_rules( 'nat', $nat_ads );

        # add the skips
        my $skip_rule = "-t nat -I slADS 5 --dst %s -m tcp -p tcp --dport 80 -j ACCEPT";
        my $skips = $class->load_allows('skips.txt');
        my $throttle = 10;
        my $i = 0;
        foreach my $skip (@{$skips}) {
            iptables(sprintf($skip_rule, $skip));
            if ($i++ % $throttle == 0) {
                warn("added $throttle skips, sleeping 1") if DEBUG;
                sleep 1;
            }
        }

        # add the noskips
        my $noskip_rule = "-t nat -I slADS 5 -p tcp -m tcp --dport 80 --dst %s -j DNAT --to-destination $Ad_proxy";
        my $noskips = $class->load_allows('noskips.txt');
        foreach my $noskip (@{$noskips}) {
            iptables(sprintf($noskip_rule, $noskip));
        }

        # add the redirect unless the search already added it.
        unless ($Config->sl_search eq 'On') {
            iptables("-t nat -I slOUT 3 -m mark --mark $Ads_mark/0x700 -j slADS");
        }

    } else {

        die 'no ad chains configured';
    }
}


sub add_rules {
    my ( $table, $rules ) = @_;

    foreach my $rule ( split( /\n/, $rules ) ) {

        chomp($rule);
        next unless $rule =~ m/\S/; # skip blanks
        warn("$$ Adding rule $rule to table $table\n") if DEBUG;
        iptables("-t $table -A $rule");
    }
}

sub clear_firewall {
    my $class = shift;

    # clear all tables
    iptables("-t $_ -F") for keys %tables_chains;

    # clear all chains
    iptables("-t $_ -X") for keys %tables_chains;

    # reset the postrouting rule
#    iptables("-t nat -A POSTROUTING -o $Wan_if -j MASQUERADE");
}

sub iptables {
    my $cmd = shift;
    system("sudo $Iptables $cmd") == 0
      or require Carp
      && Carp::confess "could not iptables '$cmd', err: $!, ret: $?\n";

    return 1;
}

sub _mac_check {
    my ( $class, $mac ) = @_;

    die "no mac passed to _mac_check" unless $mac;

    my $esc_mac = URI::Escape::uri_escape($mac);
    my $url     = "$Auth_url/check?mac=$esc_mac";

    my $res = $UA->get($url);

    if ( ( $res->code == 404 ) or ( $res->code == 401 ) ) {

        # no mac authenticated
        return $res->code;

    }
    elsif ( !$res->is_success ) {

        die $res;
    }

    return 1;
}

sub check_for_mac {
    my ( $class, $mac, $ip ) = @_;

    my $esc_mac = URI::Escape::uri_escape($mac);
    my $url     = "$Auth_url/check?mac=$esc_mac&cp_mac=" . URI::Escape::uri_escape($Wan_mac);

    my $res = $UA->get($url);

    if ( ( $res->code == 404 ) or ( $res->code == 401 ) ) {

        # no mac authenticated
        return $res->code;

    }
    elsif ( !$res->is_success ) {

        die $res;
    }

    warn( "mac check response code " . $res->code ) if DEBUG;

    my $payload = $res->content;

    my $type = ($payload =~ m/paid/) ? 'paid' : 'ads';

    # successful request, make sure the rules are ok
    my $uc_mac        = uc($mac);
    my $iptables_rule = `sudo $Iptables -t mangle -L -v`;

    # see if the mac address is in a rule
    my ($iptables_ip) =
      $iptables_rule =~ m/(\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}).*?MAC\s+$uc_mac/i;

    if ( !$iptables_ip ) {

        warn("no iptables rules, creating one") if DEBUG;

        # probably a server restart, re-add the rules
        $class->_paid_chain( 'A', $mac, $ip );

    }
    elsif ( $ip ne $iptables_ip ) {
        warn("iptables rules don't match, updating") if DEBUG;

        # dhcp lease probably expired, delete old rule, create new rule
        my $delete = "delete_from_$type\_chain";
        $class->$delete( $mac, $iptables_ip );
        my $chain = "_$type\_chain";
        $class->$chain( 'A', $mac, $ip );

    }

    return $type;
}



sub paid_users {
    my ($class) = @_;

    return $class->users($Paid_mark);
}

sub ads_users {
    my ($class) = @_;

    return $class->users($Ads_mark);
}

sub users {
    my ( $class, $mark ) = @_;

    my @users =
      map { [ $_ =~ m/(\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}).*?MAC\s(\S+)\s/ ] }
      grep { $_ =~ m/(?:$mark)/ }
      split( '\n', `sudo $Iptables -t mangle --list` );

    return @users;
}

sub _paid_chain {
    my ( $class, $op, $mac, $ip ) = @_;
    iptables(
"-t mangle -$op slOUT -s $ip -m mac --mac-source $mac -j MARK $Mark_op $Paid_mark"
    );
    iptables("-t mangle -$op slINC -d $ip -j ACCEPT");
}

sub add_to_paid_chain {
    my ( $class, $mac, $ip ) = @_;

    my $check = eval { $class->check_for_mac($mac, $ip) };
    die $@ if $@;

    return Apache2::Const::NOT_FOUND unless $check eq 'paid';

    # see if this mac is already in the ads chain
    my $ads_ip = $class->check_ads_chain_for_mac( $mac );
    if ($ads_ip) {
      warn("deleting mac $mac, ip $ip from ads chain, paid upgrade");
      $class->delete_from_ads_chain( $mac, $ads_ip );
    }

    # add the mac to the paid chain
    return $class->_paid_chain( 'A', $mac, $ip );
}

sub delete_from_paid_chain {
    my ( $class, $mac, $ip ) = @_;

    return $class->_paid_chain( 'D', $mac, $ip );
}

sub check_paid_chain_for_mac {
    my ($class, $mac ) = @_;

    return $class->_check_chain_for_mac( $Paid_mark, $mac );
}

sub _check_chain_for_mac {
    my ($class, $mark, $mac) = @_;

    $mac = uc($mac);

    my @lines = split( '\n', `sudo $Iptables -t mangle --list` );
    
    my $ip;
    foreach my $line (@lines) {

        next unless $line =~ m/^MARK/;
        last if ($ip) =
            $line =~ m/(\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}).*?MAC\s+$mac/i;
    }

    return unless $ip;
    return $ip;
}


sub check_ads_chain_for_mac {
    my ( $class, $mac ) = @_;

    return $class->_check_chain_for_mac( $Ads_mark, $mac );
}


sub add_to_ads_chain {
    my ( $class, $mac, $ip ) = @_;

    my $esc_mac = URI::Escape::uri_escape($mac);
    return $class->_ads_chain( 'A', $mac, $ip );
}


sub delete_from_ads_chain {
    my ( $class, $mac, $ip ) = @_;

    return $class->_ads_chain( 'D', $mac, $ip );
}


sub _ads_chain {
    my ( $class, $op, $mac, $ip ) = @_;

    iptables("-t mangle -$op slOUT -s $ip -m mac --mac-source $mac -j MARK $Mark_op $Ads_mark");

    iptables("-t mangle -$op slINC -d $ip -j ACCEPT");
}


sub check_overage {
    my ($class, $mac, $ip, $in, $out) = @_;

    my ($bytes_in) = $in =~ m/\d+\s+(\d+).*?$ip/;
    return 1 if $bytes_in > $Config->sl_down_overage;

    my ($bytes_out) = $out =~ m/\d+\s+(\d+).*?$ip/;
    return 1 if $bytes_out > $Config->sl_up_overage;

    return;
}

1;
