package SL::Model::App::Payment;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("Core");
__PACKAGE__->table("payment");
__PACKAGE__->add_columns(
  "payment_id",
  {
    data_type => "integer",
    default_value => "nextval('payment_payment_id_seq'::regclass)",
    is_nullable => 0,
    size => 4,
  },
  "reg_id",
  { data_type => "integer", default_value => undef, is_nullable => 0, size => 4 },
  "cts",
  {
    data_type => "timestamp without time zone",
    default_value => "now()",
    is_nullable => 1,
    size => 8,
  },
  "approved_ts",
  {
    data_type => "timestamp without time zone",
    default_value => undef,
    is_nullable => 1,
    size => 8,
  },
  "approved",
  {
    data_type => "boolean",
    default_value => "false",
    is_nullable => 1,
    size => 1,
  },
  "approved_reg_id",
  { data_type => "integer", default_value => 1, is_nullable => 0, size => 4 },
  "num_views",
  { data_type => "integer", default_value => undef, is_nullable => 0, size => 4 },
  "cpm",
  { data_type => "money", default_value => undef, is_nullable => 0, size => 4 },
  "amount",
  { data_type => "money", default_value => undef, is_nullable => 0, size => 4 },
  "pp_timestamp",
  {
    data_type => "timestamp with time zone",
    default_value => undef,
    is_nullable => 1,
    size => 8,
  },
  "pp_correlation_id",
  {
    data_type => "text",
    default_value => "''::text",
    is_nullable => 1,
    size => undef,
  },
  "pp_version",
  {
    data_type => "text",
    default_value => "''::text",
    is_nullable => 1,
    size => undef,
  },
  "pp_build",
  {
    data_type => "text",
    default_value => "''::text",
    is_nullable => 1,
    size => undef,
  },
  "payable",
  {
    data_type => "boolean",
    default_value => "false",
    is_nullable => 0,
    size => 1,
  },
  "receivable",
  {
    data_type => "boolean",
    default_value => "false",
    is_nullable => 0,
    size => 1,
  },
  "collected",
  {
    data_type => "boolean",
    default_value => "false",
    is_nullable => 0,
    size => 1,
  },
  "paid",
  {
    data_type => "boolean",
    default_value => "false",
    is_nullable => 0,
    size => 1,
  },
);
__PACKAGE__->set_primary_key("payment_id");
__PACKAGE__->belongs_to("reg_id", "SL::Model::App::Reg", { reg_id => "reg_id" });


# Created by DBIx::Class::Schema::Loader v0.04002 @ 2008-01-08 23:25:05
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:sl4oXvKotMGimPintdq8/Q

# These lines were loaded from '/Users/phred/dev/svn/sl/trunk/SL-Model/lib/SL/Model/App/Payment.pm' found in @INC.# They are now part of the custom portion of this file# for you to hand-edit.  If you do not either delete# this section or remove that file from @INC, this section# will be repeated redundantly when you re-create this# file again via Loader!

use Business::PayPal::API qw( MassPay );
use SL::Model::App;
use Mail::Mailer;

use SL::Config;
our $CFG = SL::Config->new;

use constant DEBUG => $ENV{SL_DEBUG} || 0;

# email receipt parameters
our $FROM = "SL Payment Daemon <support\@silverliningnetworks.com>";

sub new {
    my ( $class, $mode ) = @_;
    $mode ||= 'sandbox';

    my $self = {};
    bless $self, $class;
    $self->{'mode'} = $mode;

    $self->{username} =
      ( $mode eq 'production' )
      ? $CFG->sl_paypal_prod_username
      : $CFG->sl_paypal_sandbox_username;

    $self->{password} =
      ( $mode eq 'production' )
      ? $CFG->sl_paypal_prod_password
      : $CFG->sl_paypal_sandbox_password;

    $self->{signature} =
      ( $mode eq 'production' )
      ? $CFG->sl_paypal_prod_signature
      : $CFG->sl_paypal_sandbox_signature;

    $self->{email_recipient} =
      ( $mode eq 'production' )
      ? 'sl_reports@redhotpenguin.com'
      : 'fred@redhotpenguin.com';

    my %args = (
        Username  => $self->{username},
        Password  => $self->{password},
        Signature => $self->{signature},
    );

    if ( $mode eq 'sandbox' ) {
        print STDERR "Testing mode\n\n";
        $args{'sandbox'} = 1;
    }
    $self->{pp} = Business::PayPal::API->new(%args);

    return $self;
}


sub collect {
    my ( $self, $recv ) = @_;

    die "not a receivable"
      unless $recv && $recv->isa('SL::Model::App::Payment');
    die "ugh mutated transaction, DANGER!\n" . Dumper($recv) . "\n"
      unless ( ( $recv->payable == 0 )
        && ( $recv->receivable == 1 )
        && ( $recv->approved == 1 )
        && ( $recv->collected == 0 )
        && ( $recv->paid == 0 ) );

    # do a credit card authorization
    my $reg = $recv->reg_id;
    my $cc  = $reg->cc_id;

    my %resp = $self->{pp}->DoDirectPaymentRequest(
        PaymentAction     => 'Sale',
        OrderTotal        => $recv->amount,
        TaxTotal          => 0.0,
        ShippingTotal     => 0.0,
        ItemTotal         => 0.0,
        HandlingTotal     => 0.0,
        CreditCardType    => $cc->type,
        CreditCardNumber  => $cc->number,
        ExpMonth          => $cc->exp_month,
        ExpYear           => $cc->exp_year,
        CVV2              => $cc->cvvtwo,
        FirstName         => $reg->fname,
        LastName          => $reg->lname,
        Street1           => $reg->streetone,
        Street2           => $reg->streettwo,
        CityName          => $reg->city,
        StateOrProvince   => $reg->state,
        PostalCode        => $reg->zip,
        Country           => $reg->country,
        Payer             => $reg->paypal_id,
        CurrencyID        => 'USD',
        IPAddress         => $reg->last_seen_ip,
        MerchantSessionID => 420,
    );

    if ( $resp{Ack} ne 'Success' ) {
        die "Request failed: " . Dumper( \%resp ) . "\n";
    }

    $recv->pp_correlation_id( $resp{'CorrelationID'} );
    $recv->pp_timestamp( $resp{'Timestamp'} );
    $recv->pp_version( $resp{'Version'} );
    $recv->pp_build( $resp{'Build'} );
    $recv->collected(1);
    $recv->update;

    return \%resp;
}

sub receivables {
   my @sl_receivables = SL::Model::App->resultset('Payment')->search(
        {
            receivable => 1, # we get money from user
            payable   => 0,
            approved => 1,
            paid     => 0,
            collected => 0,
        }
    );
   return unless @sl_receivables;
   return \@sl_receivables;
}


# execute the payment transaction for payments that have been approved

sub pay_payments {
    my $self = shift;

    # grab approved payments that haven't been paid
    my @sl_payments = SL::Model::App->resultset('Payment')->search(
        {
            receivable    => 0,
            payable       => 1, # we are paying the user
            approved => 1,
            paid     => 0,
            collected => 0,
        }
    );

    die "no payments to make!\n" unless @sl_payments;

    print STDERR "processing payments for accounts: \n--\n"
      . join( "\n", map { $_->reg_id->paypal_id } @sl_payments )
      . "\n--\n"
      if DEBUG;

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

    if ( $self->{mode} eq 'production' ) {
        print STDERR "making mass pay request in 5 seconds...\n";
        sleep 5;
    }
    else {
        print STDERR "executing mass pay transaction\n" if DEBUG;
    }

    $self->{sl_payments} = \@sl_payments;

    my %response = $self->{pp}->MassPay(%pay_args);

    if ( $response{'Ack'} eq 'Failure' ) {
        die Dumper( \%response );
    }

    if ( $response{'Ack'} eq 'Success' ) {
        print STDERR "SUCCESSFUL PAYMENT, updating database.\n" if DEBUG;
        foreach my $sl_payment (@sl_payments) {
            $sl_payment->pp_correlation_id( $response{'CorrelationID'} );
            $sl_payment->pp_timestamp( $response{'Timestamp'} );
            $sl_payment->pp_version( $response{'Version'} );
            $sl_payment->pp_build( $response{'Build'} );
            $sl_payment->paid(1);
            $sl_payment->update;
        }
    }

    return \%response;
}

sub approve {
    my ( $self, $approver_reg ) = @_;

    if ( $self->paid == 1 ) {
        die sprintf( "payment id %d already paid!\n", $self->payment_id );
    }

    if (    ( $self->approved == 1 )
        and ( $self->approved_reg_id != 1 )
        and ( defined $self->approved_ts ) )
    {
        die sprintf( "payment id %d already approved!\n", $self->payment_id );
    }

    if (
        ( $self->approved == 1 )
        and (
            ( $self->approved_reg_id == 1 ) or    #broken
            ( !defined $self->approved_ts )
        )
      )
    {
        die sprintf( "payment id %d is BROKEN, please investigate!\n",
            $self->payment_id );
    }

    # ok approve the payment
    $self->approved_reg_id( $approver_reg->reg_id );
    $self->approved_ts(
        DateTime::Format::Pg->format_datetime( DateTime->now ) );
    $self->approved(1);
    return $self->update;
}

sub send_receipt {
    my ( $self, $args_ref ) = @_;

    my $body    = $args_ref->{body}    || die 'no body!';
    my $subject = $args_ref->{subject} || die 'no subject!';

    my $binary;
    my $qmail = `which qmail-send`;
    if ( -e $qmail ) {
        $binary = 'qmail';
    }
    else {
        $binary = 'sendmail';
    }

    my $mailer = Mail::Mailer->new($binary);
    $mailer->open(
        {
            'To'      => $self->{email_recipient},
            'From'    => $FROM,
            'Subject' => $subject
        }
    );

    print $mailer $body;
    $mailer->close;

    return 1;
}

1;
