#!perl

use strict;
use warnings;

use SL::Config;
our $CFG = SL::Config->new;

use constant DEBUG => $ENV{SL_DEBUG} || 0;

my $mode = shift || 'sandbox';

# email receipt parameters
my $FROM = "SL Payment Daemon <fred\@redhotpenguin.com>";
my $TO =
  ( $mode eq 'production' )
  ? 'sl_reports@redhotpenguin.com'
  : 'fred@redhotpenguin.com';

my $username =
  ( $mode eq 'production' )
  ? $CFG->sl_paypal_prod_username
  : $CFG->sl_paypal_sandbox_username;
my $password =
  ( $mode eq 'production' )
  ? $CFG->sl_paypal_prod_password
  : $CFG->sl_paypal_sandbox_password;

my $signature =
  ( $mode eq 'production' )
  ? $CFG->sl_paypal_prod_signature
  : $CFG->sl_paypal_sandbox_signature;

use Business::PayPal::API qw( MassPay );
use Data::Dumper;
use Mail::Mailer;

my %args = (
    Username  => $username,
    Password  => $password,
    Signature => $signature,
);

if ( $mode eq 'sandbox' ) {
    print STDERR "Testing mode\n\n";
    $args{'sandbox'} = 1;
}
elsif ( $mode eq 'production' ) {
    print STDERR "** PRODUCTION mode, commencing in 10 seconds\n\n";
    sleep 10;
    print STDERR "** beginning payment\n";
}

my $pp = Business::PayPal::API->new(%args);

# test case one, pay recipient because their router incurred ad views
use SL::Model::App;

# grab approved payments
my @sl_payments =
  SL::Model::App->resultset('Payment')->search( { approved => 1, } );

print STDERR "processing payments for accounts: \n--\n"
  . join( "\n", map { $_->reg_id->paypal_id } @sl_payments )
  . "\n--\n";

# big note make paypal api unhappy, probably only can take one line
my $note = <<'NOTE';
Here is your payment for %s from Silver Lining networks.
This payment is based on %d ad views at an average CPM rate of %s.

Thank you for being a part of the Silver Lining Network!
NOTE

# short note make api happy
my $short_note = <<'NOTE';
%s payment, %s ad views at %s CPM
NOTE

my @payment_items = map {
    {
        ReceiverEmail => $_->reg_id->paypal_id,
        Amount        => substr( $_->amount, 1, length( $_->amount ) - 1 ),
        Note => sprintf( $short_note, $_->amount, $_->num_views, $_->cpm ),

        # Note        => sprintf( $note, $_->amount, $_->num_views, $_->cpm ),
    }
} @sl_payments;

my %pay_args = (
    EmailSubject => "Silver Lining Networks Payment Notice",
    MassPayItems => \@payment_items
);

if ( $mode eq 'production' ) {
    print STDERR "making mass pay request in 5 seconds...\n";
    sleep 5;
}
else {
    print STDERR "executing mass pay transaction\n";
}

my %response = $pp->MassPay(%pay_args);

if ( $response{'Ack'} eq 'Failure' ) {
    print STDERR "FAILURE:  Paypal request failed, errors: \n"
      . Dumper( $response{'Errors'} );
}

if ( $response{'Ack'} eq 'Success' ) {
    print STDERR "SUCCESSFUL PAYMENT, updating database.\n";
    foreach my $sl_payment (@sl_payments) {
        $sl_payment->pp_correlation_id( $response{'CorrelationID'} );
        $sl_payment->pp_timestamp( $response{'Timestamp'} );
        $sl_payment->pp_version( $response{'Version'} );
        $sl_payment->pp_build( $response{'Build'} );
        $sl_payment->paid(1);
        $sl_payment->update;
    }
}

print STDERR "\n---------\nRESPONSE: \n" . Dumper( \%response ) . "\n";

# Generate the email
my $mailer;
unless (DEBUG) {

    #    $mailer = Mail::Mailer->new('qmail');
    $mailer = Mail::Mailer->new('sendmail');
    $mailer->open(
        {
            'To'      => $TO,
            'From'    => $FROM,
            'Subject' => 'SL payment summary'
        }
    );
}

my $cnt = <<CNT;
A payment event has just occurred, this is the summary.

Status:  %s

Paypal ids and amount to each
%s
CNT

$cnt = sprintf(
    $cnt,
    $response{'Ack'},
    join(
        "\n",
        map {
            sprintf( "%d - %s - %s",
                $_->payment_id, $_->reg_id->paypal_id, $_->amount, )
          } @sl_payments
    )
);

if ( $response{'Ack'} eq 'Failure' ) {
    $cnt .= "FAILURE:  Paypal request failed, errors: \n"
      . Dumper( $response{'Errors'} ) . "\n";
}

$cnt .= "\nRaw paypal response: " . Dumper( \%response ) . "\n\n";

$cnt .= "\n\nHave a nice day :)\n";

print STDERR $cnt if DEBUG;
print $mailer $cnt unless DEBUG;
$mailer->close     unless DEBUG;
