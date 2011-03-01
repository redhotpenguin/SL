package SL::DNS;

use strict;
use warnings;

=head1

SL::DNS - handles dns work

=cut

use Net::DNS;

use constant DEBUG         => $ENV{SL_DEBUG}         || 0;
use constant VERBOSE_DEBUG => $ENV{SL_VERBOSE_DEBUG} || 0;

use Data::Dumper;

our $VERSION = '0.04';
our $resolver = Net::DNS::Resolver->new;

sub resolve {
    my ( $class, $args ) = @_;

    my $hostname = $args->{hostname} || die 'hostname needed';

    if ( $args->{cache} ) {

        warn("checking dns cache for $hostname") if VERBOSE_DEBUG;
        my $ips = $args->{cache}->memd->get($hostname);

        warn( "ips: " . Dumper($ips) ) if VERBOSE_DEBUG;
        return @{$ips} if $ips;
    }

    if ( $args->{nameserver} ) {
        $resolver->nameserver( $args->{nameserver} );
    }

    warn("running dns query for $hostname") if DEBUG;
    my $ip;
    my $query = $resolver->query($hostname);

    die $resolver->errorstring unless $query;

    my @ips;

    warn( "answer: " . Dumper( $query->answer ) ) if VERBOSE_DEBUG;
    foreach my $rr ( $query->answer ) {
        next unless $rr->type eq "A";
        $ip = $rr->address;
        push @ips, $ip;
    }

    if ( $args->{cache} ) {

        $args->{cache}->memd->set( $hostname => \@ips, 3600 );
    }

    return @ips;
}

1;
