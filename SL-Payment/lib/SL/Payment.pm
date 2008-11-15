package SL::Payment;

use strict;
use warnings;

use SL::Model::App                        ();
use SL::Config                            ();
use Business::OnlinePayment::AuthorizeNet ();

our $VERSION = 0.01;

our ( $Config, $Authorize_login, $Authorize_key );

use constant DEBUG => $ENV{SL_DEBUG} || 0;

BEGIN {
    $Config          = SL::Config->new;
    $Authorize_login = $Config->sl_authorize_login || die 'payment setup error';
    $Authorize_key   = $Config->sl_authorize_key || die 'payment setup error';
}

sub process {
    my ( $class, $args ) = @_;

    die "missing args"
      unless ( defined $args->{account_id}
        && defined $args->{email}
        && defined $args->{mac}
        && defined $args->{card_number}
        && defined $args->{card_type}
        && defined $args->{card_exp}
        && defined $args->{zip}
        && defined $args->{first_name}
        && defined $args->{last_name}
        && defined $args->{amount}
        && defined $args->{cvv2}
        && defined $args->{ip}
        && defined $args->{street}
        && defined $args->{city}
        && defined $args->{state}
        && defined $args->{referer}
        && defined $args->{plan} );

    my ($last_four) = $args->{card_number} =~ m/(\d{4})$/;

    my $plan = delete $args->{plan};
    die "bad plan: $plan" unless $plan =~ m/(?:month|day|hour)/;

    my $stop =
      DateTime::Format::Pg->format_datetime(
        DateTime->now->add( $plan . 's' => 1 ) );

    # database
    my $payment = SL::Model::App->resultset('Payment')->create(
        {
            account_id => $args->{account_id},
            mac        => $args->{mac},
            amount     => $args->{amount},
            stop       => $stop,
            email      => $args->{email},
            last_four  => $last_four,
            card_type  => $args->{card_type},
            ip         => $args->{ip},
        }
    );

    $payment->update;

    # munge transaction args
    my $email = delete $args->{email};
    $args->{description}    = "$plan transaction payment for $email";
    $args->{invoice_number} = $payment->payment_id;
    $args->{customer_id}    = sprintf(
        "macaddress %s account %u",
        delete $args->{mac},
        delete $args->{account_id}
    );

    # authorize
    my $tx = Business::OnlinePayment->new('AuthorizeNet');

    $tx->content(
        login          => $Authorize_login,
        password       => $Authorize_key,
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
        expiration     => $args->{card_exp},
        type           => $args->{card_type},
        cvv2           => $args->{cvv2},
        referer        => $args->{referer},
    );
    $tx->submit;

    if ( $tx->is_success ) {
        warn "Card processed successfully: " . $tx->authorization if DEBUG;
        $payment->authorization_code( $tx->authorization );
        $payment->approved('t');
        $payment->update;
        return $payment;
    }
    else {
        warn "Card was rejected: " . $tx->error_message if DEBUG;
        $payment->error_message( $tx->error_message );
        $payment->approved('f');
        $payment->update;
        return $payment;
    }

}

1;

