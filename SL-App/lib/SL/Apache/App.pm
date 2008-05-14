package SL::Apache::App;

use strict;
use warnings;

our $VERSION = 0.16;

use Apache2::Const -compile => qw(OK SERVER_ERROR NOT_FOUND M_GET M_POST);
use Apache2::Log       ();
use Apache2::RequestIO ();
use LWP::UserAgent     ();
use URI                ();
use RPC::XML::Client   ();

use SL::App::Template ();

my $UA = LWP::UserAgent->new;
$UA->timeout(10);    # needs to respond somewhat quickly
our $TMPL = SL::App::Template->template();

use constant DEBUG => $ENV{SL_DEBUG} || 0;

=head1 METHODS

=over 4

=item C<dispatch_index>

This method serves of the master ad control panel for now

=back

=cut

sub dispatch_index {
    my ( $self, $r ) = @_;

    my %tmpl_data = (
        root  => $r->pnotes('root'),
        email => $r->user
    );
    my $output;
    my $ok = $TMPL->process( 'index.tmpl', \%tmpl_data, \$output );
    $ok
      ? return $self->ok( $r, $output )
      : return $self->error( $r, "Template error: " . $TMPL->error() );
}

sub ok {
    my ( $self, $r, $output ) = @_;

    # send successful response
    $r->no_cache(1);
    $r->content_type('text/html');
    $r->print($output);
    return Apache2::Const::OK;
}

sub error {
    my ( $self, $r, $error ) = @_;
    $r->log->error($error);
    return Apache2::Const::SERVER_ERROR;
}

sub _results_to_errors {
    my ( $self, $results ) = @_;
    my %errors;

    if ( $results->has_missing ) {
        %{ $errors{missing} } = map { $_ => 1 } $results->missing;
    }
    if ( $results->has_invalid ) {
        %{ $errors{invalid} } = map { $_ => 1 } $results->invalid;
    }
    return \%errors;
}

sub valid_link {
    return sub {
        my $dfv = shift;
        my $val = $dfv->get_current_constraint_value;

        my $response = $UA->get( URI->new($val) );
        return $val if $response->is_success;
        return;    # oops didn't validate
      }
}

sub check_openx_login {
    return sub {
        my $dfv   = shift;
        my $val   = $dfv->get_current_constraint_value;
        my $data  = $dfv->get_filtered_data;
        my $url   = $data->{url};
        my $login = $data->{login};
        my $pass  = $data->{pass};

        my $rpc_path = '/www/api/v1/xmlrpc/LogonXmlRpcService.php';
        my $uri      = URI->new( $url . $rpc_path );
        my $rpc      = RPC::XML::Client->new( $uri->as_string );

        # try to logon
        my $res = $rpc->send_request( 'logon', $login, $pass );
        if ( ref $res eq 'RPC::XML::fault' ) {
            warn( "$$ rpc fault: %s" . $res->{faultString}->value ) if DEBUG;
            return;
        }
        elsif ( ref $res eq 'RPC::XML::string' ) {

            # login attempt successful
            return $res->value;
        }
        else {
            return;
        }
    }
}

1;
