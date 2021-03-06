package SL::Model::App::Payment;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';

__PACKAGE__->load_components("InflateColumn::DateTime");

=head1 NAME

SL::Model::App::Payment

=cut

__PACKAGE__->table("payment");

=head1 ACCESSORS

=head2 payment_id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0
  sequence: 'payment_payment_id_seq'

=head2 account_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 amount

  data_type: 'money'
  is_nullable: 0

=head2 start

  data_type: 'timestamp'
  default_value: current_timestamp
  is_nullable: 0
  original: {default_value => \"now()"}

=head2 stop

  data_type: 'timestamp'
  is_nullable: 0

=head2 authorization_code

  data_type: 'text'
  is_nullable: 1

=head2 error_message

  data_type: 'text'
  is_nullable: 1

=head2 cts

  data_type: 'timestamp'
  default_value: current_timestamp
  is_nullable: 0
  original: {default_value => \"now()"}

=head2 approved

  data_type: 'boolean'
  is_nullable: 1

=head2 last_four

  data_type: 'integer'
  is_nullable: 0

=head2 card_type

  data_type: 'text'
  is_nullable: 0

=head2 mac

  data_type: 'macaddr'
  is_nullable: 0

=head2 ip

  data_type: 'inet'
  is_nullable: 0

=head2 email

  data_type: 'text'
  is_nullable: 0

=head2 md5

  data_type: 'text'
  is_nullable: 0

=head2 token_processed

  data_type: 'boolean'
  default_value: false
  is_nullable: 0

=head2 expires

  data_type: 'text'
  is_nullable: 1

=head2 voided

  data_type: 'boolean'
  default_value: false
  is_nullable: 1

=head2 order_number

  data_type: 'text'
  default_value: (empty string)
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "payment_id",
  {
    data_type         => "integer",
    is_auto_increment => 1,
    is_nullable       => 0,
    sequence          => "payment_payment_id_seq",
  },
  "account_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "amount",
  { data_type => "money", is_nullable => 0 },
  "start",
  {
    data_type     => "timestamp",
    default_value => \"current_timestamp",
    is_nullable   => 0,
    original      => { default_value => \"now()" },
  },
  "stop",
  { data_type => "timestamp", is_nullable => 0 },
  "authorization_code",
  { data_type => "text", is_nullable => 1 },
  "error_message",
  { data_type => "text", is_nullable => 1 },
  "cts",
  {
    data_type     => "timestamp",
    default_value => \"current_timestamp",
    is_nullable   => 0,
    original      => { default_value => \"now()" },
  },
  "approved",
  { data_type => "boolean", is_nullable => 1 },
  "last_four",
  { data_type => "integer", is_nullable => 0 },
  "card_type",
  { data_type => "text", is_nullable => 0 },
  "mac",
  { data_type => "macaddr", is_nullable => 0 },
  "ip",
  { data_type => "inet", is_nullable => 0 },
  "email",
  { data_type => "text", is_nullable => 0 },
  "md5",
  { data_type => "text", is_nullable => 0 },
  "token_processed",
  { data_type => "boolean", default_value => \"false", is_nullable => 0 },
  "expires",
  { data_type => "text", is_nullable => 1 },
  "voided",
  { data_type => "boolean", default_value => \"false", is_nullable => 1 },
  "order_number",
  { data_type => "text", default_value => "", is_nullable => 0 },
);
__PACKAGE__->set_primary_key("payment_id");

=head1 RELATIONS

=head2 account

Type: belongs_to

Related object: L<SL::Model::App::Account>

=cut

__PACKAGE__->belongs_to(
  "account",
  "SL::Model::App::Account",
  { account_id => "account_id" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "CASCADE" },
);


# Created by DBIx::Class::Schema::Loader v0.07002 @ 2010-11-08 15:50:46
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:htXsZS5AlQUHZNY+f9LEfg
# These lines were loaded from '/Users/phred/dev/perl-5.12.2/lib/site_perl/5.12.2/SL/Model/App/Payment.pm' found in @INC.

use Business::PayPal::API qw( MassPay DirectPayments );
use Business::PayPal::API::DirectPayments;
use Mail::Mailer;

use Config::SL;
our $CFG = Config::SL->new;

use constant DEBUG => $ENV{SL_DEBUG} || 0;

# email receipt parameters
our $FROM = "SL Payment Daemon <support\@silverliningnetworks.com>";

sub newpayment {
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
