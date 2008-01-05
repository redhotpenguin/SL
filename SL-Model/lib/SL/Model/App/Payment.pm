package SL::Model::App::Payment;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("Core");
__PACKAGE__->table("payment");
__PACKAGE__->add_columns(
    "payment_id",
    {
        data_type     => "integer",
        default_value => "nextval('payment_payment_id_seq'::regclass)",
        is_nullable   => 0,
        size          => 4,
    },
    "reg_id",
    {
        data_type     => "integer",
        default_value => undef,
        is_nullable   => 0,
        size          => 4
    },
    "cts",
    {
        data_type     => "timestamp without time zone",
        default_value => "now()",
        is_nullable   => 1,
        size          => 8,
    },
    "approved_ts",
    {
        data_type     => "timestamp without time zone",
        default_value => undef,
        is_nullable   => 1,
        size          => 8,
    },
    "approved",
    {
        data_type     => "boolean",
        default_value => "false",
        is_nullable   => 1,
        size          => 1,
    },
    "approved_reg_id",
    { data_type => "integer", default_value => 1, is_nullable => 0, size => 4 },
    "num_views",
    {
        data_type     => "integer",
        default_value => undef,
        is_nullable   => 0,
        size          => 4
    },
    "cpm",
    {
        data_type     => "money",
        default_value => undef,
        is_nullable   => 0,
        size          => 4
    },
    "amount",
    {
        data_type     => "money",
        default_value => undef,
        is_nullable   => 0,
        size          => 4
    },
    "pp_timestamp",
    {
        data_type     => "timestamp with time zone",
        default_value => undef,
        is_nullable   => 1,
        size          => 8,
    },
    "pp_correlation_id",
    {
        data_type     => "text",
        default_value => "''::text",
        is_nullable   => 1,
        size          => undef,
    },
    "pp_version",
    {
        data_type     => "text",
        default_value => "''::text",
        is_nullable   => 1,
        size          => undef,
    },
    "pp_build",
    {
        data_type     => "text",
        default_value => "''::text",
        is_nullable   => 1,
        size          => undef,
    },
    "paid",
    {
        data_type     => "boolean",
        default_value => "false",
        is_nullable   => 1,
        size          => 1,
    },
);
__PACKAGE__->set_primary_key("payment_id");
__PACKAGE__->belongs_to( "reg_id", "SL::Model::App::Reg",
    { reg_id => "reg_id" } );

# Created by DBIx::Class::Schema::Loader v0.04002 @ 2008-01-05 11:51:52
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:9Y+2z08mE3nnwZ5LI97I0Q

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

# execute the payment transaction for payments that have been approved

sub pay_payments {
    my $self = shift;

    # grab approved payments that haven't been paid
    my @sl_payments = SL::Model::App->resultset('Payment')->search(
        {
            approved => 1,
            paid     => 0,
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
