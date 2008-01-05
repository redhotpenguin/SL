#!perl

use strict;
use warnings;

use Data::Dumper;
use SL::Config;
our $CFG = SL::Config->new;

use constant DEBUG => $ENV{SL_DEBUG} || 0;

my $mode = shift || 'sandbox';

use SL::Model::App::Payment;

my $payment = SL::Model::App::Payment->new($mode);

print STDERR "payment object: \n" . Dumper($payment) . "\n\n" if DEBUG;

if ( $mode eq 'production' ) {
    print STDERR "making mass pay request in 10 seconds...\n";
    sleep 10;
}
else {
    print STDERR "executing mass pay transaction\n";
}

my $response = eval { $payment->pay_payments };

if ( $@ && ( $@ =~ /no payments to make/ ) ) {
    print STDERR "no payments to make, exiting\n";
    exit(0);
}
elsif ($@) {
    print STDERR "Payment attempt failed: $@\n\n";
    exit(1);
}
else {
    print STDERR "payment response: " . Dumper($response) . "\n\n" if DEBUG;
}

# send the payment receipts

my $cnt = <<CNT;
A payment event has just occurred.
Status:  %s
Paypal ids and amount to each
%s
CNT

$cnt = sprintf(
    $cnt,
    $response->{'Ack'},
    join(
        "\n",
        map {
            sprintf( "%d - %s - %s",
                $_->payment_id, $_->reg_id->paypal_id, $_->amount, )
          } @{ $payment->{sl_payments} }
    )
);

$cnt .= "\nRaw paypal response: " . Dumper($response) . "\n\n";

$cnt .= "Have a nice day :)\n";

# Generate the email
unless (DEBUG) {
    $payment->send_receipt(
        { subject => "SL Payment Transaction", body => $cnt } );
}
else {

    print STDERR $cnt;

}

exit(0);
