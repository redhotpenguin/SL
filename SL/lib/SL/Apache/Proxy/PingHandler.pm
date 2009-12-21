package SL::Apache::Proxy::PingHandler;

use strict;
use warnings;

use Apache2::Const -compile =>
  qw( HTTP_SERVICE_UNAVAILABLE DONE SERVER_ERROR OK );
use Apache2::Log                       ();
use Crypt::Blowfish_PP                 ();
use Sys::Load                          ();

use SL::Model                          ();
use SL::Model::Proxy::Router           ();
use SL::Config;

our $Config;

BEGIN {
  $Config = SL::Config->new;
}

use constant DEBUG    => $ENV{SL_DEBUG}             || 0;
use constant MAX_LOAD => $Config->sl_proxy_max_load || 4;

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
        my $count = `ps ax | grep -c httpd`;
        $r->log->error(
            sprintf(
                "ping db failure: sysload %s, httpd_count %s",
                $minute_avg, $count
            )
        );
        return Apache2::Const::HTTP_SERVICE_UNAVAILABLE;
    }

    # grab the mac address if there is one
	#GET /sl_secret_ping_button/00:12:CF:81:7A:E6_022 
	my ( $macaddr, $version ) =
      $r->uri =~ m/\/(\w{2}\:\w{2}\:\w{2}\:\w{2}\:\w{2}\:\w{2})(?:_(\d+))?/;
    
	unless (defined $macaddr) {

        # no mac addr means something is probably broken
        $r->log->error( "$$ no mac address in ping uri " . $r->uri );
        return Apache2::Const::SERVER_ERROR;
    }


    my %args = ( ip => $r->connection->remote_ip, macaddr => $macaddr,
				 firmware_version => $version	);

    # Grab any registered routers for this location
    $r->log->debug("looking for routers with mac $macaddr") if DEBUG;
    my $router = eval {
          SL::Model::Proxy::Router->ping_grab( \%args ) };

    if ($@) {
        require Data::Dumper;
        $r->log->error( "$$ db exception $@ grabbing registered routers for ",
            Data::Dumper::Dumper( \%args ) );
    }

    unless ($router) {

        # no routers at this ip, register this one
        $r->log->error( "registering router mac $macaddr at ip "
              . $r->connection->remote_ip );

        $router =
          eval { SL::Model::Proxy::Router->ping_register( \%args ); };

        if ( $@ or ( !$router ) ) {

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


    if ( $router->{device} eq 'mr3201a' ) {

        if ( defined $router->{adserving}
            && ( $router->{adserving} == 1 ) )
        {
            my $bytes = $r->print("Ad Serving On");
        }

        if (defined $router->{default_skips}
            && ( $router->{default_skips} ne '')) {

           my $bytes = $r->print("DefaultSkips " . $router->{default_skips});
           SL::Model::Proxy::Router->reset_events( $router->[0],
                    'default_skips' );
         }

        if (defined $router->{custom_skips}
            && ( $router->{custom_skips} ne '')) {

           my $bytes = $r->print("CustomSkips " . $router->{custom_skips}
           SL::Model::Proxy::Router->reset_events( $router->[0],
                    'custom_skips' );
         }

    }
    else {

        # see if there are any events for this router to process
        if (
            ( defined $router->{ssid} && ( $router->{ssid} ne '' ) )
            or    # ssid event
            (
                defined $router->{passwd} && ( $router->{passwd} ne '' )
            )
            or    # passwd event
            (
                defined $router->{firmware}
                && ( $router->{firmware} ne '' )
            )
            or    # firmware event
            (
                defined $router->{reboot} && ( $router->{reboot} ne '' )
            )
            or    # reboot event
            ( defined $router->{halt}
                && ( $router->{halt} ne '' ) )    # halt event
          )
        {
            my $events = '';

            $r->log->error("processing some events");
            if ( defined $router->{ssid} && ( $router->{ssid} ne '' ) )
            {
                $r->log->error(
                    "$$ ping event for ssid: " . $router->{ssid} );
                $events .= _gen_event( ssid => $router->{ssid} );
                SL::Model::Proxy::Router->reset_events( $router->[0],
                    'ssid_event' );
            }
            elsif ( defined $router->{passwd}
                && ( $router->{passwd} ne '' ) )
            {
                $r->log->error(
                    "$$ ping event for passwd: " . $router->{passwd} );
                $events .= _gen_event( passwd => $router->{passwd} );
                SL::Model::Proxy::Router->reset_events( $router->[0],
                    'passwd_event' );
            }
            elsif ( defined $router->{firmware}
                && ( $router->{firmware} ne '' ) )
            {
                $r->log->error(
                    "$$ ping event for firmware" . $router->{firmware} );
                $events .= _gen_event( firmware => $router->{firmware} );
                SL::Model::Proxy::Router->reset_events( $router->[0],
                    'firmware_event' );
            }
            elsif ( defined $router->{reboot}
                && ( $router->{reboot} ne '' ) )
            {
                $r->log->error(
                    "$$ ping event for reboot: " . $router->{reboot} );
                $events .= _gen_event( reboot => $router->{reboot} );
                SL::Model::Proxy::Router->reset_events( $router->[0],
                    'reboot_event' );
            }
            elsif ( defined $router->{halt}
                && ( $router->{halt} ne '' ) )
            {
                $r->log->error(
                    "$$ ping event for halt" . $router->{halt} );
                $events .= _gen_event( halt => $router->{halt} );
                SL::Model::Proxy::Router->reset_events( $router->[0],
                    'halt_event' );
            }

            # encrypt the events and send them to the client
            my $encrypted = _encrypt( $events, $macaddr, $version );
            my $bytes = $r->print($encrypted) if $encrypted;

        }
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
    my ( $string, $mac, $version ) = @_;
    unless ($mac) {
        require Carp && Carp::cluck("no macaddr passed");
        return;
    }

    # handle the version kludge
    $mac .= "_$version" if $version;

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
