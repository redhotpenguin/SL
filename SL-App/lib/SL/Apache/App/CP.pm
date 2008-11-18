package SL::Apache::App::CP;

use strict;
use warnings;

use Apache2::Const -compile =>
  qw(OK SERVER_ERROR NOT_FOUND M_GET M_POST REDIRECT );
use Apache2::Log        ();
use Apache2::SubRequest ();
use Apache2::Connection ();
use Apache2::Request    ();
use Apache2::SubRequest ();

use base 'SL::Apache::App';

use Data::FormValidator ();
use Data::FormValidator::Constraints qw(:closures);
use Regexp::Common qw( net );
use Mail::Mailer ();

use SL::App::Template ();
our $Tmpl = SL::App::Template->template();

use SL::Payment ();

use constant DEBUG => $ENV{SL_DEBUG} || 0;

our %Amounts = (
    hour  => '$1.99',
    day   => '$3.99',
    month => '$19.99',
);

our $From = "SLN Support <support\@silverliningnetworks.com>";

# this specific template logic
if (DEBUG) {
    require Data::Dumper;
}

use SL::Model;
use SL::Model::App;    # works for now

sub post {
    my ( $class, $r ) = @_;

    my $req      = Apache2::Request->new($r);
    my $dest_url = $req->param('url');
    my $mac = $req->param('mac');

    my $router      = $r->pnotes('router') || die 'router missing';
    my $splash_href = $router->splash_href || die 'router not configured for CP';

    my $location = $class->make_post_url( $splash_href, $dest_url );

    $r->log->info("splash page redirecting to $location for mac $mac");

    $r->headers_out->set( Location => $location );
    $r->server->add_version_component('sl');
    $r->no_cache(1);

    return Apache2::Const::REDIRECT;
}

sub make_post_url {
    my ( $class, $splash_url, $dest_url ) = @_;

    my $separator;
    if ( $splash_url =~ m/\?/ ) {

        # user has some args
        $separator = '&';
    }
    else {
        $separator = '?';
    }

    my $location = $splash_url . $separator . "url=$dest_url";

    return $location;
}

sub auth {
    my ( $class, $r ) = @_;

    $r->log->info('auth handler');

    my $req = Apache2::Request->new($r);
    my $mac = $req->param('mac');
    my $url = $req->param('url');

    unless ($mac) {
        $r->log->error( "$$ auth page called without mac from ip "
              . $r->connection->remote_ip
              . " url: "
              . $r->construct_url( $r->unparsed_uri ) );
        return Apache2::Const::NOT_FOUND;
    }

    unless ( $mac =~ m/$RE{net}{MAC}/ ) {
        $r->log->error( "$$ auth page called with invalid mac from ip "
              . $r->connection->remote_ip );
        return Apache2::Const::SERVER_ERROR;
    }

    my $output;
    my $ok = $Tmpl->process(
        'auth/index.tmpl',
        {
            mac => $mac,
            url => $url
        },
        \$output,
        $r
    );
    $ok
      ? return $class->ok( $r, $output )
      : return $class->error( $r, "Template error: " . $Tmpl->error() );
}

sub valid_plan {
    return sub {
        my $dfv = shift;
        my $val = $dfv->get_current_constraint_value;

        return $val if ( $val =~ m/(?:day|month|hour)/ );
        return;
      }
}

## NOT IMPLEMENTED YET

sub card_expired {
    return sub {
        my $dfv   = shift;
        my $val   = $dfv->get_current_constraint_value;
        my $data  = $dfv->get_filtered_data;
        my $month = $data->{month};
        my $year  = $data->{year};
        return $val;
      }
}

sub valid_month {
    return sub {
        my $dfv = shift;
        my $val = $dfv->get_current_constraint_value;

        return if $val !~ /^(\d+)$/;

        my $month = $1;

        return if $val < 1 || $val > 12;

        return $month;
      }
}

sub valid_year {
    return sub {
        my $dfv = shift;
        my $val = $dfv->get_current_constraint_value;

        return if $val !~ /^(\d+)$/;

        my $year = $1;

        $val += ( $val < 70 ) ? 2000 : 1900 if $val < 1900;
        my @now = localtime();
        $now[5] += 1900;

        return if ( $val < $now[5] ) || ( $val == $now[5] && $val <= $now[4] );

        return $year;
      }
}

sub token {
    my ( $class, $r ) = @_;

    my $req = Apache2::Request->new($r);

    my $token = $req->param('token');
    my $mac   = $req->param('mac');

    $r->log->info("token $token, mac $mac");

    unless ( $token && $mac ) {
        $r->log->error("$$ sub token called without token $token and mac $mac");
        return Apache2::Const::SERVER_ERROR;
    }

    # verify that the token is good
    my ($payment) = SL::Model::App->resultset('Payment')->search(
        {
            mac        => $mac,
            md5        => $token,
            ip         => $r->connection->remote_ip,
            account_id => $r->pnotes('router')->account_id->account_id,
            approved   => 't',
        }
    );

    unless ($payment) {
        $r->log->error(
            "$$ missing payment request for mac $mac, token $token, ip "
              . $r->connection->remote_ip );
        return Apache2::Const::NOT_FOUND;
    }

    # check to make sure this payment hasn't already been called
    if ( $payment->token_processed ) {
        $r->log->error( "$$ duplicate processing attempt for payment id "
              . $payment->payment_id . ", ip "
              . $r->connection->remote_ip );
        return Apache2::Const::NOT_FOUND;
    }

    # check to make sure the payment hasn't expired
    my $stop = DateTime::Format::Pg->parse_datetime( $payment->stop );

    if ( DateTime->now->epoch > $stop->epoch ) {

        # oops someone is trying to hack us
        $r->log->error(
            "$$ token attempt for expired payment, token $token, mac $mac, ip "
              . $r->connection->remote_ip
              . ", stop time "
              . $stop->mdy . " "
              . $stop->hms
              . " payment id "
              . $payment->payment_id );
        return Apache2::Const::NOT_FOUND;
    }

    # ok the payment looks valid, return ok
    $payment->token_processed(1);
    $payment->update;

    $r->log->info("token $token, mac $mac VERIFIED");

    return Apache2::Const::OK;
}

sub paid {
    my ( $class, $r, $args_ref ) = @_;

    my $req = $args_ref->{req} || Apache2::Request->new($r);

    my $mac = $req->param('mac');
    unless ($mac) {
        $r->log->error( "$$ auth page called without mac from ip "
              . $r->connection->remote_ip
              . " url: "
              . $r->construct_url( $r->unparsed_uri ) );
        return Apache2::Const::NOT_FOUND;
    }

    unless ( $mac =~ m/$RE{net}{MAC}/ ) {
        $r->log->error( "$$ auth page called with invalid mac from ip "
              . $r->connection->remote_ip );
        return Apache2::Const::SERVER_ERROR;
    }

    my $router = $r->pnotes('router');
    unless ($router) {
        $r->log->error('router not set');
        return Apache2::Const::SERVER_ERROR;
    }

    # apache request bug
    my $plan = $req->param('plan');

    # plan passed on GET
    my %tmpl_data = (
        errors => $args_ref->{errors},
        req    => $req,
    );

    if ( $r->method_number == Apache2::Const::M_GET ) {

        my $output;
        my $ok = $Tmpl->process( 'auth/paid.tmpl', \%tmpl_data, \$output, $r );

        return $class->ok( $r, $output ) if $ok;
        return $class->error( $r, "Template error: " . $Tmpl->error() );
    }
    elsif ( $r->method_number == Apache2::Const::M_POST ) {

        ## processing a payment, here we go

        # reset method to get for redirect
        $r->method_number(Apache2::Const::M_GET);

        my %payment_profile = (
            required => [
                qw( first_name last_name card_type card_number cvv2
                  month year street city zip state email plan mac )
            ],
            constraint_methods => {
                email => email(),
                zip   => zip(),
                month => valid_month(),
                year  => valid_year(),

#                 month       => card_expired( { fields => ['month','year'] } ),
                card_type   => cc_type(),
                card_number => cc_number( { fields => ['card_type'] } ),
                plan        => valid_plan(),
                mac         => qr/$RE{net}{MAC}/,
            }
        );

        $r->log->info("$$ about to validate form");
        my $results = Data::FormValidator->check( $req, \%payment_profile );

        # handle form errors
        if ( $results->has_missing or $results->has_invalid ) {
            if (DEBUG) {
                $r->log->error( "results: " . Data::Dumper::Dumper($results) );
            }

            my $errors = $class->SUPER::_results_to_errors($results);
            return $class->paid(
                $r,
                {
                    errors => $errors,
                    req    => $req
                }
            );
        }

        $r->log->info("$$ about to process payment");
        ## process the payment
        my $account = $r->pnotes('router')->account_id;
        my $amount  = $Amounts{ $req->param('plan') };
        my $payment = SL::Payment->process(
            {
                account_id  => $account->account_id,
                mac         => $req->param('mac'),
                amount      => $amount,
                email       => $req->param('email'),
                card_type   => $req->param('card_type'),
                card_number => $req->param('card_number'),
                card_exp =>
                  join( '/', $req->param('month'), $req->param('year') ),
                cvv2       => $req->param('cvv2'),
                email      => $req->param('email'),
                zip        => $req->param('zip'),
                first_name => $req->param('first_name'),
                last_name  => $req->param('last_name'),
                ip         => $r->connection->remote_ip,
                street     => $req->param('street'),
                city       => $req->param('city'),
                state      => $req->param('state'),
                referer    => $r->headers_in->{'referer'},
                plan       => $req->param('plan'),
            }
        );

        if ( $payment->error_message ) {

            # process errors
            $r->log->info(
                "$$ got payment errors: " . $payment->error_message );

            return $class->paid(
                $r,
                {
                    errors => { payment => $payment->error_message, },
                    req    => $req,
                }
            );
        }

        $r->log->info( "$$ payment auth code "
              . $payment->authorization_code
              . " processed OK" );

        # payment success, send receipt
        ($payment) =
          SL::Model::App->resultset('Payment')
          ->search( { payment_id => $payment->payment_id } );
        my $authorization_code = sprintf( "%s", $payment->authorization_code );
        my $email              = $req->param('email');
        my $mailer             = Mail::Mailer->new('qmail');
        $mailer->open(
            {
                'To'      => $email,
                'From'    => $From,
                'CC'      => $From,
                'Subject' => $account->name
                  . " network access payment receipt $authorization_code",
            }
        );

        my $network_name = $account->name;
        my $mail         = <<"MAIL";
Hi $email,

Thank you for purchasing wifi access with $network_name for the period of
one $plan at a cost of $amount.  Your confirmation number is $authorization_code.

Please contact us at support\@silverliningnetworks.com if have any questions.

Sincerely,

Silver Lining Networks Support

MAIL

        print $mailer $mail;

        $mailer->close;

        $r->log->info("$$ receipt for payment $authorization_code: $mail");

        ## payment successful, redirect to auth
        my $redirect_url = "http://"
          . $r->pnotes('router')->lan_ip . '/paid'
          . '?token='
          . $payment->md5;

        $r->log->info("redirecting to $redirect_url");

        $r->headers_out->set( Location => $redirect_url );
        $r->no_cache(1);
        return Apache2::Const::REDIRECT;
    }
}

sub free {
    my ( $class, $r, $args_ref ) = @_;

    my $req = $args_ref->{req} || Apache2::Request->new($r);

    # apache request bug
    my $plan     = $req->param('plan');
    my $mac      = $req->param('mac');
    my $dest_url = $req->param('url');

    my $router = $r->pnotes('router');
    unless ($router) {
        $r->log->error('router not set');
        return Apache2::Const::SERVER_ERROR;
    }

    my $splash_href = $router->splash_href
      || die 'router not configured for CP';

    my $location = $class->make_post_url( $splash_href, $dest_url );

    ## payment successful, redirect to auth
    $r->headers_out->set( Location => "http://"
          . $r->pnotes('router')->lan_ip
          . "/ads?mac=$mac&url=$location" );
    $r->no_cache(1);
    return Apache2::Const::REDIRECT;
}

1;
