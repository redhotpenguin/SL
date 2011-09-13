package SL::DNS::Nameserver;

use 5.010001;
use strict;
use warnings;

our $VERSION = 0.04;

use base 'Net::DNS::Nameserver';

use Net::DNS::Resolver;
use Net::DNS::RR;
use Data::Dumper;
use Config::SL;
use Cache::Memcached;
use Time::HiRes qw( gettimeofday tv_interval );

# initialize configuration vars
our $Config = Config::SL->new;

our $Debug     = $ENV{SL_DEBUG}     || $Config->debug || 0;
our $Ttl       = $Config->rr_ttl    || die;
our $Search_ip = $Config->search_ip || die;
our $Monitor   = $Config->monitor   || die;

our %Search_domains = $Config->search_domains;
die unless keys %Search_domains;

our $Search_override = $Config->search_override || 0;

our @Cacheservers = $Config->cacheservers;
die unless @Cacheservers;

our @Nameservers =
  `cat /etc/resolv.conf` =~ m/nameserver\s(\d+\.\d+\.\d+\.\d+)/g;

our $Cache = Cache::Memcached->new( { servers => \@Cacheservers } );

# test the cache
$Cache->set( "foobar" => 1 );
die "cache inactive!\n" unless $Cache->get('foobar');

sub new {
    my ( $class, $args ) = @_;

    # default to development settings
    my $port = $args->{port} || die;
    my $ip   = $args->{ip}   || die;
    my $verbose = $args->{verbose};

    my $ns = $class->SUPER::new(
        LocalAddr    => $ip,
        LocalPort    => $port,
        Verbose      => $verbose,
        ReplyHandler => \&reply_handler,
    );

    my %self = ( ns => $ns );

    bless \%self, $class;

    return \%self;
}

sub run {
    my $self = shift;
    $self->{ns}->main_loop;
}

sub reply_handler {
    my ( $qname, $qclass, $qtype, $peerhost, $query, $conn ) = @_;

    my ( $rcode, @ans, @auth, @add );

    my $t0 = [gettimeofday];

    # return response for the monitor
    if ($qname eq $Monitor) {  

        push @ans, monitor_rr( $qname, $qtype );
        return ( 'NOERROR', \@ans, [], [], { aa => 1 } );
    }

    my $log = "[query] $peerhost [" . localtime() . "] $qclass $qtype $qname";

    # redirect search traffic.  moo haha haha.  ha.
    my ($rquery, $redir_search);
    if (
        (
               ( $qtype eq 'A' )
            or ( $qtype eq 'CNAME' )
        )
        and $Search_override
        and ( grep { $qname eq $_ } keys %Search_domains )
      )
    {

        print "found search redirect domain $qname\n" if $Debug;
	$log .= ' 302';
        $redir_search = 1;
    }
    else {

        # not a search redirect domain, see if this entry is cached
        $rquery = $Cache->get("$qtype|$qname");

        if ( !$rquery ) {    # not in cache

            print "[debug] no cache $qname $qtype, resolving\n" if $Debug;

            my $Resolver = Net::DNS::Resolver->new(
                nameservers => \@Nameservers,
                recurse     => 1,
                debug       => $Debug,
            );

            $rquery = $Resolver->query( $qname, $qtype );

            if ( $Resolver->errorstring ne 'NOERROR' ) {

                # handle errors
                if ( ( $qtype eq 'A' ) or ( $qtype eq 'CNAME' ) ) {

                    # send the ip of the search service
                    $log .= ' 500';
                    $redir_search = 1;

                }
                else {

                    # send the error response
                    # dear god please cleanup this crap code
                    $rcode = $Resolver->errorstring;
                    $log .= ' 500';

		    my $elapsed = tv_interval( $t0, [gettimeofday]) * 1000;
		    $log .= sprintf(' %.2f', $elapsed);
		    print $log . "\n";

                    return ( $rcode, [], [], [], { aa => 1 } );

                }
            }
            else {

                unless ($rquery) {

                    # no rquery means no domain
                    $log .= ' 404';

		    my $elapsed = tv_interval( $t0, [gettimeofday]) * 1000;
		    $log .= sprintf(' %.2f', $elapsed);
		    print $log . "\n";
                    return ( 'NXDOMAIN', [], [], [], { aa => 1 } );
                }

                print "setting cache entry $qtype|$qname\n" if $Debug;
                $Cache->set( "$qtype|$qname" => $rquery, $Ttl );
	    	$log .= ' 200';

            }
        }
        else {
            print "found cache entry for $qname|$qtype\n" if $Debug;
	    $log .= ' 304';
        }
    }

    # set the search redirect
    if ($redir_search) {
        print "Adding search rr record\n" if $Debug;
        push @ans, search_rr( $qname, $qtype );
    }
    else {

        # or build the response
        print "rquery " . Dumper($rquery) if $Debug;

        foreach my $rr ( $rquery->answer ) {
            print "rr: " . Dumper($rr) if $Debug;

            $rr->ttl($Ttl);

            # cname override for our search domains
            if (    ( $rr->type eq 'CNAME' )
                and ( grep { $_ eq $rr->name } keys %Search_domains )
                and $Search_override )
            {

                push @ans, search_rr( $rr->name, 'A' );
                last;
            }
            else {

                push @ans, $rr;
            }
        }

    }

    $rcode ||= "NOERROR";

    print " answer  " . Dumper( \@ans ) if $Debug;

    my $elapsed = tv_interval( $t0, [gettimeofday]) * 1000;
    $log .= sprintf(' %.2f', $elapsed);
    # print the log entry
    print $log . "\n";

    # mark the answer as authoritive (by setting the 'aa' flag)
    return ( $rcode, \@ans, \@auth, \@add, { aa => 1 } );
}

sub monitor_rr {
    my ( $qname, $qtype ) = @_;

    my $rr = Net::DNS::RR->new("$qname\. 1 $qtype 127.0.0.1");
    
    return $rr;
} 

sub search_rr {
    my ( $qname, $qtype ) = @_;

    my $search_ip = $Search_ip;
    if ( exists $Search_domains{$qname} ) {
        $search_ip = $Search_domains{$qname};
    }

    my $rr = Net::DNS::RR->new("$qname\. $Ttl $qtype $search_ip");

    return $rr;
}

1;
__END__

=head1 NAME

SL-DNS-Nameserver - Silver Lining Networks select based nameserver

=head1 SYNOPSIS

  use SL::DNS::Nameserver;

  my $ns = SL::DNS::Nameserver->new;

  $ns->run;

=head1 DESCRIPTION

SLN select based DNS server.

=head2 EXPORT

None by default.



=head1 SEE ALSO

Net::DNS

=head1 AUTHOR

Fred Moyer, E<lt>fred@slwifi.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2011 by Silver Lining Networks

This is proprietary software, you may not redistribute.

=cut
