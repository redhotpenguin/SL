package SL::Apache::Proxy::PingHandler;

use strict;
use warnings;

use Apache2::Const -compile => qw( HTTP_SERVICE_UNAVAILABLE DONE SERVER_ERROR );
use Apache2::Log                       ();
use Sys::Load                          ();
use SL::Model                          ();
use SL::Model::Proxy::Router           ();
use SL::Model::Proxy::Router::Location ();
use Crypt::Blowfish_PP                 ();

use constant DEBUG => $ENV{SL_DEBUG} || 0;

use SL::Config;
our $CONFIG;

BEGIN {
    $CONFIG = SL::Config->new();
}

use constant MAX_LOAD => $CONFIG->sl_proxy_max_load || 2;

use constant SSID     => 2;
use constant PASSWD   => 3;
use constant FIRMWARE => 4;
use constant REBOOT   => 5;
use constant HALT     => 6;

sub handler {
    my $r = shift;

    $r->server->add_version_component('sl');
    $r->no_cache(1);
    $r->rflush;

    # check the load
    my $minute_avg = [ Sys::Load::getload() ]->[0];
    if ( $minute_avg > MAX_LOAD ) {
        $r->log->error(
            "System max load " . MAX_LOAD . " exceeded: $minute_avg" );
        return Apache2::Const::HTTP_SERVICE_UNAVAILABLE;
    }

    # check the database
    my $dbh = eval { SL::Model->connect() };
    if ( !$dbh or $@ ) {
        if ($@) {
            $r->log->error(
                sprintf( "exception thrown in ping check: %s", $@ ) );
        }
        my $post_count = `ps ax | grep -c post`;
        $r->log->error(
            sprintf(
                "ping db failure: sysload %s, pg_count %s",
                $minute_avg, $post_count
            )
        );
        return Apache2::Const::HTTP_SERVICE_UNAVAILABLE;
    }

    # grab the mac address if there is one
    my ($macaddr) = $r->uri =~ m/\/(\w{2}\:\w{2}\:\w{2}\:\w{2}\:\w{2}\:\w{2})$/;

	# handle perlbal proxy
	if (defined $r->headers_in->{'X-Forwarded-For'}) {
	    $r->connection->remote_ip($r->headers_in->{'X-Forwarded-For'});
	}

	my %args = ( ip => $r->connection->remote_ip );
    if ( defined $macaddr ) {
        $r->log->debug("$$ Macaddr $macaddr\n") if DEBUG;
        $args{'macaddr'} = $macaddr;
    }
    else {

        # no mac addr means something is probably broken
        $r->log->error( "$$ no mac address in ping uri " . $r->uri );
        return Apache2::Const::HTTP_SERVICE_UNAVAILABLE;
    }

    # Grab any registered routers for this location
    my $router_ref =
      eval { SL::Model::Proxy::Router::Location->get_registered( \%args ) };
    if ($@) {
        require Data::Dumper;
        $r->log->error( "$$ db exception $@ grabbing registered routers for ",
            Data::Dumper::Dumper( \%args ) );
    }

    unless ($router_ref) {

        # no routers at this ip, register this one
        $r->log->error( "$$ registering router mac $macaddr at ip "
              . $r->connection->remote_ip );

        $router_ref =
          eval { SL::Model::Proxy::Router::Location->register( \%args ); };

        if ( $@ or ( !$router_ref ) ) {

            # handle registration failure
            $r->log->error( sprintf("$$ error $@ registering router") ) if $@;

            require Data::Dumper;
            $r->log->error(
                sprintf( "$$ error registering router args %s",
                    Data::Dumper::Dumper( \%args ) )
            );
            return Apache2::Const::HTTP_SERVICE_UNAVAILABLE;
        }
    }

    $r->log->debug("$$ ping ok for mac $macaddr") if DEBUG;

    # see if there are any events for this router to process
    if (
        ( defined $router_ref->[SSID] )     or    # ssid event
        ( defined $router_ref->[PASSWD] )   or    # passwd event
        ( defined $router_ref->[FIRMWARE] ) or    # firmware event
        ( defined $router_ref->[REBOOT] )   or    # reboot event
        ( defined $router_ref->[HALT] )           # halt event
      )
    {
        my $events = '';

        if ( $router_ref->[SSID] ) {
            $r->log->debug("$$ ping event for ssid") if DEBUG;
            $events .= _gen_event( ssid => $router_ref->[SSID] );
            SL::Model::Proxy::Router->reset_events( $router_ref->[0], 'ssid_event' );
        }
        elsif ( $router_ref->[PASSWD] ) {
            $r->log->debug("$$ ping event for passwd") if DEBUG;
            $events .= _gen_event( passwd => $router_ref->[PASSWD] );
            SL::Model::Proxy::Router->reset_events( $router_ref->[0], 'passwd_event' );
        }
        elsif ( $router_ref->[FIRMWARE] ) {
              $r->log->debug("$$ ping event for firmware") if DEBUG;
              $events .= _gen_event( firmware => $router_ref->[FIRMWARE] );
              SL::Model::Proxy::Router->reset_events( $router_ref->[0], 'firmware_event' );
        }
        elsif ( $router_ref->[REBOOT] ) {
              $r->log->debug("$$ ping event for reboot") if DEBUG;
              $events .= _gen_event( reboot => $router_ref->[REBOOT] );
              SL::Model::Proxy::Router->reset_events( $router_ref->[0], 'reboot_event' );
        }
        elsif ( $router_ref->[HALT] ) {
              $r->log->debug("$$ ping event for halt") if DEBUG;
              $events .= _gen_event( halt => $router_ref->[HALT] );
              SL::Model::Proxy::Router->reset_events( $router_ref->[0], 'halt_event' );
        }

        my $encrypted = _encrypt( $events, $macaddr );

        # encrypt the events
        my $bytes = $r->print($encrypted) if $encrypted;

    }

    return Apache2::Const::DONE;
}

sub _gen_event {
      my ( $type, $data ) = @_;
      unless ($data) {
          warn("no data passed to _gen_event for type $type");
          return;
      }

      return "$type:$data\n";
}

sub _encrypt {
      my ( $string, $mac ) = @_;
      unless ($mac) {
          require Carp && Carp::cluck("no macaddr passed");
          return;
      }

      my $mac_salt = join( '', reverse( split( ':', $mac ) ) );
      warn("$$ mac salt is $mac_salt") if DEBUG;
      my $blowfish = Crypt::Blowfish_PP->new($mac_salt);

      # split the string into 8 byte pieces and encrypt
      my @groups = ( $string =~ /.{1,8}/gs );
      warn( "$$ groups are " . join( ',', @groups ) ) if DEBUG;

      my $encrypted = '';
      foreach my $member (@groups) {
          $encrypted .= $blowfish->encrypt($member);
      }

      return $encrypted;
}

1;
