package SL::App::Checkin;

use strict;
use warnings;

use Apache2::Const -compile => qw(OK HTTP_SERVICE_UNAVAILABLE NOT_FOUND);
use Apache2::Log        ();
use Apache2::Request    ();
use Apache2::Connection ();

use base 'SL::App';
use SL::Model::App;
use Data::Dumper;

use constant DEBUG => $ENV{SL_DEBUG} || 0;

sub dispatch_index {
    my ( $class, $r ) = @_;

    my $url = $r->construct_url( $r->unparsed_uri );
    $r->log->debug("handling url $url") if DEBUG;

    # we get checkin string with unescaped + signs, so use args
    my %args;
    my @pairs = split( /\&/, $r->args );
    foreach my $pair (@pairs) {

        my ( $key, $value ) = split( /\=/, $pair );
        $args{$key} = $value || 0;
    }
    $r->log->debug( "args string: " . $r->args )  if DEBUG;
    $r->log->debug( "args: " . Dumper( \%args ) ) if DEBUG;

    my $ip  = $r->connection->remote_ip;
    my $mac = $args{mac};

    unless ( $mac
        && defined $args{users}
        && defined $args{kbup}
        && defined $args{kbdown} )
    {

        $r->log->error("missing args for device at ip $ip");
        return Apache2::Const::SERVER_ERROR;
    }

    my ($router) =
      SL::Model::App->resultset('Router')->search( { macaddr => $mac } );

    unless ($router) {
        $r->log->error("no router found with mac $mac");
        return Apache2::Const::NOT_FOUND;
    }

    # update the router time
    my $now = DateTime->now;
    $now->set_time_zone('local');
    $router->last_ping( DateTime::Format::Pg->format_datetime($now) );

    # update the ip
    unless ( defined $router->wan_ip && ($router->wan_ip eq $ip) ) {
        $router->wan_ip($ip);
    }

    # update the latest seen users
    $router->clients( $args{users} );

    # gateway or repeater?
    my ( $speed, $units );
    if ( ( defined $args{role} ) && ( $args{role} eq 'G' ) ) {

        $router->gateway( $router->wan_ip );
        $router->speed_test(
            sprintf( "This gateway node has WAN IP %s", $router->wan_ip ) );

    }
    elsif ( ( defined $args{role} ) && ( $args{role} eq 'R' )
      &&  (defined($args{gateway})))
    {

	my $gateway;
      if (substr( $args{gateway}, 0, 1) ==5 )  {
     		($gateway) =
          SL::Model::App->resultset('Router')->search( {
                                         ip => $args{gateway} } );
    }

    if ($gateway) {

	$router->gateway($args{gateway});

	$router->speed_test(
	            sprintf(
	                "%d hops, %d ms ping and %s to gateway %s",
	                $args{hops}, $args{RTT}, $args{NTR}, $gateway->name
	            )
	);
        # calculate throughput to gateway
        ( $speed, $units ) = split( /\-/, $args{NTR} );
        if ( defined $units && $units eq 'MB/s' ) {
            $speed = int( $speed * 1024 );
        }
        elsif ( $units ne 'KB/s' ) {
            $r->log->error("Unknown checkin units '$units'");
        }


	my $hops = ($args{hops} == 1) ? 'hop' : 'hops';
        $router->speed_test(
            sprintf(
                "%d %s, %d ms ping and %2.1f Mbits/s to gateway %s",
                $args{hops}, $hops, $args{RTT}, $speed/1024*8, $gateway->name
            )
        );
	}
    }
    else {

        # default is gateway
        $router->gateway($router->wan_ip);
        $router->speed_test(
            sprintf( "This gateway node has WAN IP %s", $router->wan_ip ) );

    }
    $router->update;



    # log the router entry
    my $checkin = SL::Model::App->resultset('Checkin')->create(
        {
            router_id    => $router->router_id,
            memfree      => $args{memfree} || 0,
            users        => $args{users} || 0,
            kbup         => $args{kbup} || 0,
            kbdown       => $args{kbdown} || 0,
            ping_ms      => sprintf( '%d', $args{RTT} || 0 ),
            speed_kbytes => sprintf( '%d', $speed || 0),
            nodes        => $args{nodes},
            nodes_rssi   => $args{rssi},
	    gateway_quality => $args{'gw-qual'} || 0
        }
    );

    $r->log->debug( "new checkin entry for " . $router->router_id ) if DEBUG;

    # log user data if there is any
    my $top_users = $args{top_users};
    if ( defined $top_users ) {

        $r->log->debug("processing user string $top_users") if DEBUG;
        my @users = split( /\+/, $top_users );

        shift(@users);    # first part of split is blank
        $r->log->debug( "users: " . Dumper( \@users ) ) if DEBUG;

        my %users;
        foreach my $line (@users) {
            my ( $kbtotal, $kbdown, $kbup, $usermac, $hostname ) =
              split( /\,/, $line );

            my $usertrack = SL::Model::App->resultset('Usertrack')->create(
                {
                    router_id => $router->router_id,
                    totalkb   => $kbtotal,
                    kbup      => $kbup,
                    kbdown    => $kbdown,
                    mac       => $usermac,
                }
            );

            $r->log->debug("new checkin for user $usermac") if DEBUG;

        }
    }

    $r->content_type('text/plain');
    $r->print("FOO");
    return Apache2::Const::OK;
}

# handles ajax move icon requests

sub dispatch_move {
    my ( $class, $r ) = @_;

    my $req = Apache2::Request->new($r);

    # we get checkin string with unescaped + signs, so use args
    my $mac = $req->param('mac');
    my $lat = $req->param('lat');
    my $lng = $req->param('lng');

    return Apache2::Const::SERVER_ERROR unless ( $mac && $lng && $lat );

    # BAD - no access controls
    my ($router) = SL::Model::App->resultset('Router')->search(
        {
            active  => 't',
            macaddr => $mac
        }
    );

    $r->log->debug(
        sprintf(
            "Updating router %s to lat %s, lng %s",
            $router->name, $lng, $lat
        )
    ) if DEBUG;

    $router->lng($lng);
    $router->lat($lat);
    $router->update;

    return Apache2::Const::OK;
}

1;
