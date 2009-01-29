package SL::Payment;

use strict;
use warnings;

use SL::Model::App ();
use SL::Config     ();

use CGI ();
CGI->compile(':all');

use Business::PayPal                      ();
use Business::OnlinePayment::AuthorizeNet ();
use DateTime ();
use DateTime::Format::Pg ();
use Data::Dumper ();

# some globals

our $VERSION = 0.03;

our ( $Config, $Authorize_login, $Authorize_key, $Business, $Notify_url,
    $Return );

BEGIN {
    $Config          = SL::Config->new;
    $Authorize_login = $Config->sl_authorize_login || die 'payment setup error';
    $Authorize_key   = $Config->sl_authorize_key || die 'payment setup error';
    $Business        = 'paypal@silverliningnetworks.com';
    $Notify_url = 'https://app.silverliningnetworks.com/sl/paypal/notify';
    $Return     = 'https://app.silverliningnetworks.com/sl/paypal/return';
}

our %Plans = (
    'test'  => { duration => { 'hours'  => 1 }, cost => '$0.01', },
    'one'   => { duration => { 'hours'  => 1 }, cost => '$2.00', },
    'four'  => { duration => { 'hours'  => 4 }, cost => '$3.00', },
    'day'   => { duration => { 'days'   => 1 }, cost => '$5.00', },
    'month' => { duration => { 'months' => 1 }, cost => '$25.00', },
);

# some constants

use constant DEBUG     => $ENV{SL_DEBUG}     || 0;
use constant TEST_MODE => $ENV{SL_TEST_MODE} || 0;

sub _plan_from_cost {
    my ($class, $cost) = @_;

    foreach my $plan (keys %Plans) {
	return $Plans{$plan} if $Plans{$plan}->{cost} eq '$' . $cost;
    }

    die "No plan found for cost $cost";
}

sub plan {
    my ( $class, $plan ) = @_;

    unless ($plan) {
        require Carp && Carp::confess("SL::Payment::plan called without plan");
    }

    return $Plans{$plan};
}

sub paypal_button {
    my ( $class, $plan, $cancel_return, $item_name, $quantity ) = @_;

    die
"Missing plan $plan, quantity $quantity, cancel_return $cancel_return, item_name $item_name\n"
      unless ( $plan
        && $cancel_return
        && $item_name
        && $quantity );

    my $paypal = Business::PayPal->new;
    my $button = $paypal->button(
        business      => $Business,
        item_name     => $item_name,
	item_number   => 429,
        return        => $Return,
        cancel_return => $cancel_return,
        amount        => SL::Payment->plan($plan)->{cost},
        quantity      => $quantity,
        notify_url    => $Notify_url,
        button_image  => CGI::image_button(
            -name => 'submit',
            -alt  => 'PayPal',
            -src =>  'https://www.paypal.com/en_US/i/logo/PayPal_mark_60x38.gif',
        ),
    );

    return ( $button, $paypal->id );
}

sub paypal_save {
    my ($class, $args) = @_;

    die "transaction not completed for " . $args->{custom} . "\n"
        unless $args->{payment_status} eq 'Completed';

    my $plan = eval { $class->_plan_from_cost($args->{payment_gross}); };
    die $@ if $@;

    my $stop =
      DateTime::Format::Pg->format_datetime(
        DateTime->now( time_zone => 'local' )->add( %{$plan->{duration}} ) );


    # ok save the payment
    my $payment = eval { SL::Model::App->resultset('Payment')->create(
        {
            account_id => $args->{account_id},
            mac        => $args->{mac},
            amount     => $args->{payment_gross},
            stop       => $stop,
            email      => $args->{email},
            last_four  => '0',
            card_type  => 'paypal',
            ip         => $args->{ip},
            expires    => 'N/A',
        }

    ); };

    if ($@) {
        die "Error in paypal_save: " . Data::Dumper::Dumper($args) . ", $@";
    }

    return $payment;
}

sub recurring {
    my ( $class, $args ) = @_;

    die "missing args"
      unless (
           defined $args->{email}
        && defined $args->{card_number}
        && defined $args->{card_type}
        && defined $args->{card_exp}
        && defined $args->{zip}
        && defined $args->{first_name}
        && defined $args->{last_name}
        && defined $args->{cvv2}
        && defined $args->{ip}
        && defined $args->{street}
        && defined $args->{city}
        && defined $args->{state}
        && defined $args->{referer}
        && defined $args->{amount} );

    # authorize
    my $tx = Business::OnlinePayment->new('AuthorizeNet');

    my %tx_content = (
        login          => $Authorize_login,
        password       => $Authorize_key,
        action         => 'Recurring Authorization',
        interval       => '1 month',
        start          => DateTime->now->ymd,
        periods        => 60,
        trialperiods   => 0,
        trialamount    => 0,
        description    => $args->{description},
        amount         => $args->{amount},
        invoice_number => 815420,
        customer_id    => substr( $args->{first_name} . $args->{last_name}, 0, 20),
        first_name     => $args->{first_name},
        last_name      => $args->{last_name},
        address        => $args->{street},
        city           => $args->{city},
        state          => $args->{state},
        zip            => $args->{zip},
        card_number    => $args->{card_number},
        expiration     => $args->{card_exp},
        type           => $args->{card_type},
        cvv2           => $args->{cvv2},
        referer        => $args->{referer},
        email          => $args->{email},
    );

    $tx->content(%tx_content);

    if (TEST_MODE) {
        warn( "TEST_MODE enabled, would have posted " .
             Data::Dumper::Dumper( \%tx_content ) );
        return { auth_code => 1 };
    }
    else {
        $tx->submit;
    }

    if ( $tx->is_success  ) {
        warn "Card processed successfully: " . $tx->order_number if DEBUG;
        return { auth_code => $tx->order_number };
    }
    else {
        warn "Card was rejected: " . $tx->error_message if DEBUG;
        return { error => $tx->error_message };
    }
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
        && defined $args->{cvv2}
        && defined $args->{ip}
        && defined $args->{street}
        && defined $args->{city}
        && defined $args->{state}
        && defined $args->{referer}
        && defined $args->{plan} );

    my ($last_four) = $args->{card_number} =~ m/(\d{4})$/;

    my $plan = delete $args->{plan};
    my $plans = join('|', keys %Plans);
    die "bad plan: $plan" unless $plan =~ m/(?:$plans)/;

    my $duration = $class->plan($plan)->{duration};

    my $stop =
      DateTime::Format::Pg->format_datetime(
      DateTime->now( time_zone => 'local' )->add( $duration ) );

    # database
    my $amount = $class->plan( $plan )->{cost};
    my $payment = SL::Model::App->resultset('Payment')->create(
        {
            account_id => $args->{account_id},
            mac        => $args->{mac},
            amount     => $amount,
            stop       => $stop,
            email      => $args->{email},
            last_four  => $last_four,
            card_type  => $args->{card_type},
            ip         => $args->{ip},
            expires    => $args->{card_exp},
        }
    );

    $payment->update;

    # munge transaction args
    my $email = delete $args->{email};
    $args->{description}    = "Plan $plan transaction payment for $email";
    $args->{invoice_number} = $payment->payment_id;
    $args->{customer_id} =
      sprintf( "%s %u", delete $args->{mac}, delete $args->{account_id} );

    # authorize
    my $tx = Business::OnlinePayment->new('AuthorizeNet');

    my %tx_content = (
        login          => $Authorize_login,
        password       => $Authorize_key,
        action         => 'Normal Authorization',
        description    => $args->{description},
        amount         => $amount,
        invoice_number => $args->{invoice_number},
        customer_id    => $args->{customer_id},
        first_name     => $args->{first_name},
        last_name      => $args->{last_name},
        address        => $args->{street},
        city           => $args->{city},
        state          => $args->{state},
        zip            => $args->{zip},
        card_number    => $args->{card_number},
        expiration     => $args->{card_exp},
        type           => $args->{card_type},
        cvv2           => $args->{cvv2},
        referer        => $args->{referer},
        email          => $args->{email},
    );

    $tx->content(%tx_content);

    if (TEST_MODE) {
        warn(
            "TEST_MODE enabled, would have posted " .
             Data::Dumper::Dumper( \%tx_content ) );
    }
    else {
        $tx->submit;
    }

    if ( $tx->is_success or TEST_MODE ) {
        unless (TEST_MODE) {
            warn "Card processed successfully: " . $tx->authorization if DEBUG;
            $payment->authorization_code( $tx->authorization );
        }
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

