#!microperl

#use strict;
#use warnings;

my $file = shift or die 'no file';
my $fh;
open( $fh, '<', $file ) or die $!;
my $processed = 0;
my $lines     = 0;
use Crypt::Blowfish_PP;
my $mac      = '00:1a:70:e6:86:ef';
my $blowfish =
  Crypt::Blowfish_PP->new( join ( '', reverse( split ( '', $mac ) ) ) );

my $encrypted_event;
while ( my $line = <$fh> ) {
    return unless ( $line or $lines++ );
    $encrypted_event = $line;
}

my @groups = ( $encrypted_event =~ /.{1,8}/gs );

my $decrypted = '';
foreach my $member (@groups) {
    $decrypted .= $blowfish->decrypt($member);
}

foreach my $event ( split ( "\n", $decrypted ) ) {
    chomp($event);
    my ( $sub, $arg ) = split ( /:/, $event );
    next unless $arg;    # encryption junk

    print STDERR "sub $sub, arg $arg\n";
    no strict 'refs';
    my $ok = $sub->($arg);
    print "OK\n\n" if $ok;
}

sub ssid {
    my $arg = shift;
    warn("HEY WORLD, SSID WITH ARG $arg");
    return 1;
}
sub passwd {
    my $arg = shift;
    warn("HEY WORLD, PASSWD WITH ARG $arg");
    return 1;
}


sleep 1;