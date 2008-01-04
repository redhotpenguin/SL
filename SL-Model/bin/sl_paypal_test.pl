#!perl

use strict;
use warnings;

use SL::Config;
our $CFG = SL::Config->new;

my $username  = $CFG->sl_paypal_username;
my $password  = $CFG->sl_paypal_password;
my $signature = $CFG->sl_paypal_signature;

use Business::PayPal::API qw( MassPay );

my $pp = Business::PayPal::API->new(
    Username  => $username,
    Password  => $password,
    Signature => $signature,
    sandbox   => 1
);

# test case one, pay recipient because their router incurred ad views
use SL::Model::App;

# grab approved payments
my @sl_payments = SL::Model::App->resultset('Payment')->search(
    {
        approved     => 1,
    }
);

my $note = <<'NOTE';
Here is your payment for %s from Silver Lining networks.
This payment is based on %d ad views at an average CPM rate of %s.

Thank you for being a part of the Silver Lining Network!
NOTE

my @payment_items = map {
    {
        ReceiverEmail => $_->reg_id->paypal_id,
          Amount      => $_->amount,
          Note        => sprintf( $note, $_->amount, $_->num_views, $_->cpm ),
    }
} @sl_payments;

my %response = $pp->MassPay(
    EmailSubject => "Silver Lining Networks payment receipt",
    MassPayItems => \@payment_items
);

use Data::Dumper;
print STDERR "response: \n" . Dumper(\%response);
