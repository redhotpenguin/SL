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
    print STDERR "collecting receivables request in 10 seconds...\n";
    sleep 10;
}
else {
    print STDERR "collecting receivable transaction\n";
}

my @receivables = $payment->receivables;

unless (@receivables) {
  print STDERR "no receivables to collect, exiting\n";
  exit(0);
}

my (@errors, @responses);
foreach my $receivable ( @receivables ) {
  my $response = eval { $payment->collect($receivable); };
  push @responses, $response if $response;
  push @errors, $@ if $@;
}
if (@errors) {
    print STDERR "encountered errors: " . Dumper(\@errors);
}

print STDERR "responses: " . Dumper(\@responses) . "\n\n" if DEBUG;

# send the payment receipts

my $cnt = <<CNT;
A number of receivables have just been collected.

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
          } @{ $payment->{sl_receivables} }
    )
);

$cnt .= "\nERRORS: " . Dumper(\@errors) . "\n" if @errors;

$cnt .= "\nRaw paypal response: " . Dumper(\@responses) . "\n\n";

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
