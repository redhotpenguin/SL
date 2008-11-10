package SL::Payment;

use strict;
use warnings;

use SL::Model::App                        ();
use SL::Config                            ();
use Business::OnlinePayment::AuthorizeNet ();
use Mail::Mailer                          ();

our $VERSION = 0.01;

our $Config;

use constant DEBUG => $ENV{SL_DEBUG} || 0;

BEGIN {
    $Config = SL::Config->new;
}

sub make_payment {
    my ( $class, $args ) = @_;

    my ($last_four) = $arg->{card_number} =~ m/(\d{4})$/;

    my $duration = delete $args->{duration} . 's';
    die "bad duration: $duration" unless $duration =~ m/(?:month|day|hour)/;

    my $stop =
      DateTime::Format::Pg->format_datetime(
        DateTime->now->add( $duration => 1 ) );

    # database
    my $payment = SL::Model::App->resultset('Payment')->create(
        {
            account_id => $args->{account_id},
            mac        => $args->{mac},
            amount     => $args->{amount},
            stop       => $stop,
            email      => $args->{email}
            last_four  => $last_four,
            type       => $args->{card_type},
        }
    );

    $payment->update;

    # munge transaction args
    my $email = delete $args->{email};
    $args->{description}    = "$duration transaction payment for $email";
    $args->{invoice_number} = $payment->payment_id;
    $args->{customer_id}    = sprintf(
        "user %u account %u",
        delete $args->{usr_id},
        delete $args->{account_id}
    );

    my $tx = $class->_make_transaction($args);

    if ( $tx->is_success ) {
        warn "Card processed successfully: " . $tx->authorization if DEBUG;
        $payment->authorization_code( $tx->authorization );
        $payment->approved('t');
        $payment->update;
    }
    else {
        warn "Card was rejected: " . $tx->error_message if DEBUG;
        $payment->error_message( $tx->error_message );
        $payment->approved('f');
        $payment->update;
        return;
    }

    # send the email receipt
    my $from   = "SLN Support <support\@silverliningnetworks.com>";
    my $mailer = Mail::Mailer->new('qmail');
    $mailer->open(
        {
            'To'      => $email,
            'From'    => $from,
            'CC'      => $from,
            'Subject' => 'Payment receipt'
        }
    );

    my $authorization_code = $tx->authorization;
    print $mailer <<MAIL;
Hi $to,

Thank you for purchasing wifi access with Silver Lining Networks for the period of
one $duration.  Your confirmation number is $authorization.

Please contact us at support\@silverliningnetworks.com if have any questions.

Sincerely,

Silver Lining Networks Support

MAIL

    $mailer->close

      return 1;

}

sub _make_transaction {
    my ( $class, $args ) = @_;

    # authorize
    my $tx = Business::OnlinePayment->new('AuthorizeNet');

    $tx->content(
        type           => $args->{card_type},
        login          => $Config->login,
        password       => $Config->key,
        action         => 'Normal Authorization',
        description    => $args->{description},
        amount         => $args->{amount},
        invoice_number => $args->{invoice_number},
        customer_id    => $args->{customer_id},
        first_name     => $args->{first_name},
        last_name      => $args->{last_name},
        address        => $args->{address},
        city           => $args->{city},
        state          => $args->{state},
        zip            => $args->{zip},
        card_number    => $args->{card_number},
        expiration     => $args->{expiration},
        cvv2           => $args->{cvv2},
        referer        => $args->{referer},
    );
    $tx->submit;

    return $tx;
}

1;

