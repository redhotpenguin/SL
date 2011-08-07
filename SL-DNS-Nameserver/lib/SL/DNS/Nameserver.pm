package SL::DNS::Nameserver;

use 5.014001;
use strict;
use warnings;

our $VERSION = 0.01;

use base 'Net::DNS::Nameserver';

use Net::DNS::Resolver;
use Net::DNS::RR;

use Data::Dumper;
use Config::SL;

# initialize configuration vars
our $Config = Config::SL->new;

our $Debug          = $ENV{SL_DEBUG}          || $Config->debug || 0;
our $Ttl            = $Config->rr_ttl         || die;
our $Search_ip      = $Config->search_ip      || die;
our @Search_domains = $Config->search_domains || die;
our $Port           = $Config->port           || die;
our $Ip             = $Config->ip             || die;

sub new {
    my ( $class, $args ) = @_;

    # default to development settings
    my $port    = $args->{port}    || $Port;
    my $ip      = $args->{ip}      || $Ip;
    my $verbose = $args->{verbose} || 1;

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

    print "Received query from $peerhost to " . $conn->{"sockhost"} . "\n"
      if $Debug;

    if (
        (
               ( $qtype eq 'A' )
            or ( $qtype eq 'CNAME' )
        )
        and grep { $qname eq $_ } @Search_domains
      )
    {

        print "found search redirect domain $qname\n" if $Debug;

        push @ans, search_rr( $qname, $qtype );
    }
    else {

        print " resolving $qname $qtype\n" if $Debug;

        my $Resolver = Net::DNS::Resolver->new(
            nameservers => [qw( 192.168.1.1 )],
            recurse     => 1
        );

        my $rquery = $Resolver->query( $qname, $qtype );

        if ( $Resolver->errorstring ne 'NOERROR' ) {

            # handle errors
            if ( ( $qtype eq 'A' ) or ( $qtype eq 'CNAME' ) ) {

                # send the ip of the search service
                push @ans, search_rr( $qname, $qtype );

            }
            else {

                $rcode = $Resolver->errorstring;

            }
        }
        elsif ($rquery) {

            print "rquery " . Dumper($rquery) if $Debug;

            foreach my $rr ( $rquery->answer ) {
                print "rr: " . Dumper($rr) if $Debug;

                $rr->ttl($Ttl);

                # cname override for our search domains
                if (   ( $rr->type eq 'CNAME' )
                    && ( grep { $_ eq $rr->name } @Search_domains ) )
                {

                    push @ans, search_rr( $rr->name, 'A' );
                    last;
                }
                else {

                    push @ans, $rr;
                }
            }
        }

    }

    $rcode ||= "NOERROR";

    print " answer  " . Dumper( \@ans ) if $Debug;

    # mark the answer as authoritive (by setting the 'aa' flag)
    return ( $rcode, \@ans, \@auth, \@add, { aa => 1 } );
}

sub search_rr {
    my ( $qname, $qtype ) = @_;

    my $rr = Net::DNS::RR->new("$qname\. $Ttl $qtype $Search_ip");

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