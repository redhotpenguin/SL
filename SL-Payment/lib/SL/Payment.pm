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
use Data::Dumper;

# some globals

our $VERSION = 0.04;

our ( $Config, %Authorize_creds, $Business, $Notify_url, $Return );

BEGIN {
    $Config          = SL::Config->new;
    %Authorize_creds = (
        login          => $Config->sl_authorize_login || die,
        password       => $Config->sl_authorize_key || die,
    ),
    $Business        = 'paypal@silverliningnetworks.com';
    $Notify_url = 'https://app.silverliningnetworks.com/sl/paypal/notify';
    $Return     = 'https://app.silverliningnetworks.com/sl/paypal/return';
}

our %Plans = (
    'test'  => { duration => { 'hours'  => 1 }, cost => '$0.18', },
    'one'   => { duration => { 'hours'  => 1 }, cost => '$2.00', },
    'four'  => { duration => { 'hours'  => 4 }, cost => '$3.00', },
    'day'   => { duration => { 'days'   => 1 }, cost => '$5.00', },
    'month' => { duration => { 'months' => 1 }, cost => '$15.00', },
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
        die "Error in paypal_save: " . Dumper($args) . ", $@";
    }

    return $payment;
}

sub last_four {
  my $card = shift;
  return substr($card, length($card)-4);
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

    ####################################################
    # place a small authorization on the account to check the card credentials

    my $tx = Business::OnlinePayment->new('AuthorizeNet');

    my %common_args = (
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
        email          => $args->{email},
        referer        => $args->{referer},
    );

    my %auth_args = (
        invoice_number => '42069',
        action         => 'Authorization Only',
        amount         => $Plans{test}->{cost},
        description    => sprintf('publisher %s card verification', $args->{email}),
    );

    $tx->content( %Authorize_creds, %common_args, %auth_args, );

    if (TEST_MODE) {
        warn( "TEST_MODE enabled, auth args " . Dumper( $tx->content ) );

    }
    else {

        $tx->submit;

        if ( $tx->is_success  ) {
            warn(sprintf("Card verified, auth %s, order %s: ",
                         $tx->authorization, $tx->order_number)) if DEBUG;
        }
        else {
            warn "Card was rejected: " . $tx->error_message if DEBUG;
            return { error => $tx->error_message };
        }
    }

    ########################################
    # make a new payment first
    my $payment = SL::Model::App->resultset('Payment')->create(
        {
            account_id => 1,
            mac        => 'FF:FF:FF:FF:FF:FF',
            amount     => $args->{amount},
            stop       => DateTime::Format::Pg->format_datetime(
                             DateTime->now( time_zone => 'local' )->add(months => 60)),
            email      => $args->{email},
            last_four  => last_four($args->{card_number}),
            card_type  => $args->{card_type},
            ip         => $args->{ip},
            expires    => 'N/A',
        }
    );
    $payment->update or return { error => 'Payment system is temporarily unavailable' };

    # make the subscription request
    my %arb_args = (
        invoice_number => $payment->payment_id,
        action         => 'Recurring Authorization',
        interval       => '1 month',
        start          => DateTime->now->ymd,
        periods        => 60,
        trialperiods   => 0,
        trialamount    => 0,
        description    => $args->{description},
        amount         => $args->{amount},
    );

    if (defined $args->{special}) {

      # half off first three months
      if ($args->{special} eq 'half_first_three') {
        $arb_args{trialperiods} = 3;
        $arb_args{trialamount} = ($args->{amount} / 2);
      }
    }

    $tx->content(%Authorize_creds, %common_args, %arb_args);

    if (TEST_MODE) {
        warn( "TEST_MODE enabled, would have posted " . Dumper( $tx->content ) );
        $payment->approved('t');
        $payment->token_processed('t');
        $payment->authorization_code( $payment->payment_id );
    }
    else {
        $tx->submit;

        if ( $tx->is_success  ) {
          warn("Subscription processed successfully: " . $tx->order_number) if DEBUG;
          $payment->approved('t');
          $payment->token_processed('t');
          $payment->authorization_code( $payment->order_number );
        }
        else {
          warn "Card was rejected: " . $tx->error_message if DEBUG;
          $payment->approved('t');
          $payment->token_processed('t');
          $payment->error_message( $tx->error_message );
        }
    }

    $payment->update;
    return $payment;
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
            last_four  => last_four($args->{card_number}),
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
        %Authorize_creds,
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
        warn("TEST_MODE enabled, would have posted " . Dumper( $tx->content ) );
        $payment->authorization_code( $payment->payment_id );
        $payment->approved('t');
    }
    else {
        $tx->submit;

        if ( $tx->is_success ) {
            warn "Card processed successfully: " . $tx->authorization if DEBUG;
            $payment->authorization_code( $tx->authorization );
            $payment->approved('t');
        }
        else {
            warn "Card was rejected: " . $tx->error_message if DEBUG;
            $payment->error_message( $tx->error_message );
        }
    }

    $payment->update;
    return $payment;
}

1;

