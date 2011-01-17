package SL::App::Settings;

use strict;
use warnings;

use Apache2::Const -compile => qw( OK M_POST M_GET HTTP_METHOD_NOT_ALLOWED);
use Apache2::Log        ();
use Apache2::Request    ();
use Apache2::Upload     ();
use Apache2::ServerUtil ();
use Data::FormValidator ();
use Data::FormValidator::Constraints qw(:closures);
use Digest::MD5 ();

use SL::App::Template ();
use SL::Config        ();
use SL::Model::App    ();
use base 'SL::App';

use Data::Dumper;

our $Config    = SL::Config->new();
our $TMPL      = SL::App::Template->template();

use constant DEBUG => $ENV{SL_DEBUG} || 0;

sub dispatch_index {
    my ( $self, $r ) = @_;

    if ( $r->method_number == Apache2::Const::M_GET ) {

        my %tmpl_data;
        my $output;

        if ( $r->pnotes( $r->user )->root ) {
            my @accounts =
              SL::Model::App->resultset('Account')->search( { active => 't' } );
            $tmpl_data{accounts} =
              [ sort { $a->plan cmp $b->plan } sort { lc( $a->name ) cmp lc( $b->name ) } @accounts ];
        }

        $TMPL->process( 'settings/index.tmpl', \%tmpl_data, \$output, $r )
          || return $self->error( $r, $TMPL->error );
        return $self->ok( $r, $output );
    }
}

sub dispatch_root {
    my ( $self, $r, $args_ref ) = @_;

    my $reg = $r->pnotes( $r->user );
    return $self->error( $r, "Root error for " . $r->user ) unless $reg->root;

    # this user can proceed
    my $req = $args_ref->{req} || Apache2::Request->new($r);
    my $account_id = $req->param('account_id');
    return $self->error( $r, "No account for " . $r->user ) unless $account_id;
    $reg->account_id($account_id);
    $reg->update;

    $r->pnotes('session')->{msg} =
      "Account changed to " . $reg->account->name;
    $r->headers_out->set( Location => $r->headers_in->{'Referer'} );
    return Apache2::Const::REDIRECT;

}

sub dispatch_market {
    my ( $self, $r, $args_ref ) = @_;

    my $reg = $r->pnotes( $r->user );
    my $req = $args_ref->{req} || Apache2::Request->new($r);

    if ( $req->param('marketplace') ) {

        $r->log->debug("setting marketplace to " . $req->param('marketplace')) if DEBUG;

	my $advertise_here = $req->param('marketplace');
	if ($advertise_here eq 'http://www.silverliningnetworks.com/site/advertise_here.html?') {
		$advertise_here .= 'network=' . $reg->account_id;
	}

        $reg->account->advertise_here( $advertise_here );
    }
    else {
        $r->log->debug("setting marketplace to off") if DEBUG;
        $reg->account->advertise_here('http://www.silverliningnetworks.com/site/advertise_here.html?network=' . $reg->account_id);
    }

    $r->pnotes('session')->{msg} = "Advertise Here Link Updated";
    $reg->account->update;
    $r->headers_out->set( Location => $r->headers_in->{'Referer'} );
    return Apache2::Const::REDIRECT;
}


sub dispatch_affiliates {
    my ( $self, $r, $args_ref ) = @_;

    my $reg = $r->pnotes( $r->user );
    my $req = $args_ref->{req} || Apache2::Request->new($r);

    if ( $req->param('google_ad_client') ) {

        $r->log->debug("setting google_ad_client to " . $req->param('google_ad_client')) if DEBUG;

        $reg->account->google_ad_client( $req->param('google_ad_client' ));
    }
    else {
        $reg->account->google_ad_client('pub-9104946517470276');
    }

    $r->pnotes('session')->{msg} = "AdSense ID Updated";
    $reg->account->update;
    $r->headers_out->set( Location => $r->headers_in->{'Referer'} );
    return Apache2::Const::REDIRECT;
}


sub dispatch_account {
    my ( $self, $r, $args_ref ) = @_;

    my $reg = $r->pnotes( $r->user );
    my $req = $args_ref->{req} || Apache2::Request->new($r);
    my $email = $req->param('email');    # libapreq workaround

    if ( $r->method_number == Apache2::Const::M_GET ) {

        my %tmpl_data = (
            errors => $args_ref->{errors},
            req    => $req,
            reg    => $reg,
        );

        my $output;
        $TMPL->process( 'settings/account.tmpl', \%tmpl_data, \$output, $r )
          || return $self->error( $r, $TMPL->error );
        return $self->ok( $r, $output );
    }
    elsif ( $r->method_number == Apache2::Const::M_POST ) {

        $r->method_number(Apache2::Const::M_GET);

        my %profile = (
            required           => [qw( current_email  email account )],
            optional           => [qw( password retype )],
            constraint_methods => {
                email => [
                    email(),
                    not_current_user(
                        { fields => [ 'email', 'current_email' ] },
                    )
                ],
                password => SL::App::check_password(
                    { fields => [ 'retype', 'password' ] }
                ),
            },
        );

        my $results = Data::FormValidator->check( $req, \%profile );

        $r->log->debug( "$$ form errors:" . Data::Dumper::Dumper($results) )
              if DEBUG;


        if ( $results->has_missing or $results->has_invalid ) {
            my $errors = $self->SUPER::_results_to_errors($results);

            $r->log->debug( "$$ form errors:" . Data::Dumper::Dumper($errors) )
              if DEBUG;

            return $self->dispatch_account(
                $r,
                {
                    errors => $errors,
                    req    => $req
                }
            );
        }

    }

    my $account = $reg->account;
    if ( $account->name ne $req->param('account') ) {

        # we need to update the account
        my $oldbase         = $account->report_base;
        my $old_report_base = join( '/tmp/',
            substr( $oldbase, 0, length($oldbase) - 7 ) );

        # update the account
        $account->name( $req->param('account') );
        $account->update;
        my $newbase         = $account->report_base;
        my $new_report_base = join( '/tmp/',
            substr( $newbase, 0, length($newbase) - 7 ) );

        if (-d $old_report_base) {
          system("mv $old_report_base $new_report_base") == 0 or die $!;
        }
    }

    # update the password
    $reg->password_md5( Digest::MD5::md5_hex( $req->param('password') ) );

    my $update_cookies;
    if ( $reg->email ne $req->param('email') ) {
        $update_cookies = 1;
    }

    foreach my $param (qw( email )) {
        $reg->$param( $req->param($param) );
    }
    $reg->update;

    if ($update_cookies) {

        # gah I hate this part
        # re-auth the user
        $r->user( $reg->email );
        $r->pnotes( $r->user => $reg );
        SL::App::CookieAuth->send_cookie( $r, $reg,
            $r->pnotes('session')->{_session_id} );
    }

    $r->pnotes('session')->{msg} = "Account settings have been updated";

    $r->headers_out->set( Location => $Config->sl_app_proxy
                  . $Config->sl_app_base_uri . '/app/settings/index');
    return Apache2::Const::REDIRECT;
}

sub dispatch_uptime {
    my ( $self, $r, $args_ref ) = @_;

    my $output;
    $TMPL->process( 'settings/uptime.tmpl', {}, \$output, $r )
      || return $self->error( $r, $TMPL->error );
    return $self->ok( $r, $output );
}

sub dispatch_users {
    my ( $self, $r, $args_ref ) = @_;

    my $reg = $r->pnotes( $r->user );
    my $req = $args_ref->{req} || Apache2::Request->new($r);

    my @users =
      SL::Model::App->resultset('Reg')
      ->search( { account_id => $reg->account->account_id } );

    if ( $r->method_number == Apache2::Const::M_GET ) {
        my %tmpl_data = (
            errors => $args_ref->{errors},
            users  => \@users,
        );

        my $output;
        $TMPL->process( 'settings/users.tmpl', \%tmpl_data, \$output, $r )
          || return $self->error( $r, $TMPL->error );
        return $self->ok( $r, $output );
    }

}

sub dispatch_payment {
    my ( $self, $r, $args_ref ) = @_;

    my $reg = $r->pnotes( $r->user );
    my $req = $args_ref->{req} || Apache2::Request->new($r);

    my @payments = SL::Model::App->resultset('Payment')->search(
        {
            account_id => $reg->account->account_id,
            amount     => { '>' => '$0.00' },
        },
        { order_by => 'me.start DESC', }
    );

    # total up the payments
    my $total = 0;
    foreach my $payment (@payments) {
        next
          unless defined $payment->approved
          && defined $payment->token_processed;
        next
          unless ( $payment->approved == 1 )
          && ( $payment->token_processed == 1 );
        next if defined $payment->voided && $payment->voided == 1;

        my $amount = $payment->amount;
        $amount =~ s/^\$(\d+)\.\d+$/$1/;
        next unless $amount > 0.01;
        $total += $amount;
    }

    if ( $r->method_number == Apache2::Const::M_GET ) {

	my $slgateway;
	if (substr($reg->account->advertise_here, 0, 31) eq 'http://www.silverliningnetworks') {
		$slgateway=1;
	}

        my %tmpl_data = (
  	    slgateway => $slgateway,
	    req      => $req,
            total    => $total,
            payments => \@payments,
            errors   => $args_ref->{errors},
            ip       => $r->connection->remote_ip,
        );

        my $output;
        $TMPL->process( 'settings/payment.tmpl', \%tmpl_data, \$output, $r )
          || return $self->error( $r, $TMPL->error );
        return $self->ok( $r, $output );
    }
    else {
        return Apache2::Const::HTTP_METHOD_NOT_ALLOWED;
    }
}

sub valid_card {
    return sub {
        my $dfv  = shift;
        my $val  = $dfv->get_current_constraint_value;
        my $data = $dfv->get_filtered_data;

        my $paypal = SL::Model::App::Payment->new('sandbox');

        warn( "Running valid card, my paypal object is "
              . Data::Dumper::Dumper($paypal) );

        my %resp = $paypal->{pp}->DoDirectPaymentRequest(
            PaymentAction     => 'Authorization',
            OrderTotal        => 1.00,
            TaxTotal          => 0.0,
            ShippingTotal     => 0.0,
            ItemTotal         => 0.0,
            HandlingTotal     => 0.0,
            CreditCardType    => $data->{brand},
            CreditCardNumber  => $data->{number},
            ExpMonth          => $data->{expires_month},
            ExpYear           => $data->{expires_year},
            CVV2              => $data->{cvv},
            FirstName         => $data->{first_name},
            LastName          => $data->{last_name},
            Street1           => $data->{streetone},
            Street2           => $data->{streettwo},
            CityName          => $data->{city},
            StateOrProvince   => $data->{state},
            PostalCode        => $data->{zip},
            Country           => $data->{country},
            Payer             => $data->{email},
            CurrencyID        => 'USD',
            IPAddress         => $data->{ip},
            MerchantSessionID => 420,
        );

        if ( $resp{Ack} ne 'Success' ) {

            warn(   "paypal request failed:"
                  . Data::Dumper::Dumper( \%resp )
                  . "\n" );
            return;

        }
        else {

            warn(
                "request succeeded: " . Data::Dumper::Dumper( \%resp ) . "\n" );
            return $val;
        }
      }
}

sub not_current_user {
    return sub {
        my $dfv     = shift;
        my $val     = $dfv->get_current_constraint_value;
        my $data    = $dfv->get_filtered_data;
        my $email   = $data->{email};
        my $current = $data->{current_email};

        return $val if ( $email eq $current );    # no change

        my ($reg) =
          SL::Model::App->resultset('Reg')->search( { email => $email } );
        return if $reg;                           # oops duplicate user attempt;

        return $val;
      }
}

sub valid_threshold {
    return sub {
        my $dfv = shift;
        my $val = $dfv->get_current_constraint_value;

        return $val if ( ( $val =~ m/^\d{1,3}$/ ) && ( $val > 4 ) );
        return;
      }
}

1;
