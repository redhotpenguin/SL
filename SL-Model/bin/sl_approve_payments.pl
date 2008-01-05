#!perl

use strict;
use warnings;

=head1 NAME

 sl_approve_payments.pl

=head1 SYNOPSIS

 perl sl_approve_payments.pl --email='fred@redhotpenguin.com' --payment_id=1 --payment_id=2

 perl sl_approve_payments.pl --help

 perl sl_approve_payments.pl --man

=cut

use Getopt::Long;
use Pod::Usage;

my ( $email, @payment_ids );
my ( $help,  $man );

pod2usage(1) unless @ARGV;
GetOptions(
    'email=s'      => \$email,
    'payment_id=i' => \@payment_ids,
    'help'         => \$help,
    'man'          => \$man,
) or pod2usage(2);

pod2usage(1) if $help;
pod2usage( -verbose => 2 ) if $man;

use SL::Model::App;
my @payments =
  SL::Model::App->resultset('Payment')
  ->search( { payment_id => { -in => \@payment_ids } } );

unless ( scalar(@payment_ids) == scalar(@payments) ) {
    my %payment_obj_ids = map { $_->payment_id } @payments;
    my @missing_payment_ids =
      grep { !exists $payment_obj_ids{$_} } @payment_ids;
    print STDERR "Sorry, we could not find payment records for these ids: "
      . join( ',', @missing_payment_ids ) . "\n\n";
    exit(1);
}

my ($reg) = SL::Model::App->resultset('Reg')->search( { email => $email } );
unless ($reg) {
    print STDERR
      "Sorry no one with email $email is allowed to approve payments\n";
    exit(1);
}

use Data::Dumper;
use SL::Config;
our $CFG = SL::Config->new;

use constant DEBUG => $ENV{SL_DEBUG} || 0;

use SL::Model::App::Payment;

my $payment = SL::Model::App::Payment->new;

print STDERR "payment object: \n" . Dumper($payment) . "\n\n" if DEBUG;

print STDERR "approving pay transactions\n";

my @failed_to_approve;
foreach my $payment (@payments) {
    eval { $payment->approve($reg) };
    push @failed_to_approve, { id => $payment->payment_id, payload => $@ }
      if $@;
}

if (@failed_to_approve) {
    print STDERR "the following transactions failed to approve: "
      . join( ", ", map { $_->{id} } @failed_to_approve ) . "\n\n";
    print STDERR "payload: " . Dumper( \@failed_to_approve ) . "\n\n";
}
else {
    print STDERR "all transactions successfully approved!\n";
}

my $cnt = <<CNT;
A payment approval event has just occurred.
Paypal ids and amount to each
%s
CNT

$cnt = sprintf(
    $cnt,
    join(
        "\n",
        map {
            sprintf( "%d - %s - %s",
                $_->payment_id, $_->reg_id->paypal_id, $_->amount, )
          } @payments
    )
);

if (@failed_to_approve) {
    $cnt .= "\nThese payment ids failed: "
      . join( ", ", map { $_->{id} } @failed_to_approve );
}

$cnt .= "\n\nHave a nice day :)\n";

# Generate the email
unless (DEBUG) {
    $payment->send_receipt(
        { subject => "SL Payment Approval Event", body => $cnt } );
}
else {

    print STDERR $cnt;

}

exit(0);
