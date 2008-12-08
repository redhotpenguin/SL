#!/usr/bin/perl

use strict;
use warnings;

use Getopt::Long;
use Pod::Usage;
use Email::Valid;
use SL::Model::App;

=head1 NAME

 sl_pay.pl

=head1 SYNOPSIS

 add payments to the database.  good for crediting users who run into errors
 or permanently authenticating devices.  Here is the code I used to 
 permanently authenticate jrichardson@aircloud.com netbook.

 sl_pay.pl --account='aircloud' --mac='00:15:AF:6C:10:EA' --amount='$0.00' \
     --stop='2029-12-31 23:59:59' --email='jrichardson@aircloud.com' \
     --last_four='0000' --card_type='sysadmin' --ip='127.0.0.1' --expires='never'

 sl_pay.pl --help

 sl_pay.pl --man

=cut

# Config options
my (
    $account,   $mac,       $amount, $stop, $email,
    $last_four, $card_type, $ip,     $expires
);
my ( $help, $man );

pod2usage(1) unless @ARGV;
GetOptions(
    'account=s'   => \$account,
    'mac=s'       => \$mac,
    'amount=s'    => \$amount,
    'stop=s'      => \$stop,
    'email=s'     => \$email,
    'last_four=i' => \$last_four,
    'card_type=s' => \$card_type,
    'ip=s'        => \$ip,
    'expires=s'   => \$expires,
    'help'        => \$help,
    'man'         => \$man,
) or pod2usage(2);

pod2usage(1) if $help;
pod2usage( -verbose => 2 ) if $man;

if (0) {    # invalid args combo
    exit(0);
}

# you may proceed

my $args;

( $args->{account_id} ) =
  SL::Model::App->resultset('Account')->search( { name => $account } );

$args->{account_id} = $args->{account_id}->account_id;
die "no account found for name '$account'\n" unless defined $args->{account_id};

die "invalid mac '$mac'\n" unless ( $mac =~ m/^([0-9a-fA-F]{2}([:-]|$)){6}$/i );

die "invalid amount '$amount'\n" unless ( $amount =~ m/\$\d{1,2}\.\d{2}/ );

$args->{stop} = DateTime::Format::Pg->parse_datetime($stop)
  || die "stop $stop format '2003-01-16 23:12:01' needed\n";

$args->{stop}->set_time_zone('local');

$args->{email} = $email
  if Email::Valid->address($email) || die "email $email invalid\n";

$args->{last_four} = $last_four if $last_four =~ m/^\d{4}$/;

$args->{card_type} = $card_type;

$args->{expires} = $expires;

my %create = (
    account_id         => $args->{account_id},
    mac                => $mac,
    amount             => $amount,
    stop               => $stop,
    email              => $args->{email},
    last_four          => $last_four,
    card_type          => $args->{card_type},
    ip                 => $ip,
    expires            => $args->{expires},
    approved           => 't',
    token_processed    => 't',
    authorization_code => '4200',
);
use Data::Dumper;
warn("creating payment in 5 seconds, please review submission");
warn( Dumper( \%create ) );
sleep 5;

my $payment = SL::Model::App->resultset('Payment')->create( \%create );

warn( sprintf( "new payment id %i created\n", $payment->payment_id ) );

1;

__END__
