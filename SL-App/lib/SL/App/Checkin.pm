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

sub handler {
    my $r = shift;

    # we get checkin string with unescaped + signs, so use args
    my %args;
    my @pairs = split( /\&/, $r->args );
    foreach my $pair (@pairs) {

        my ( $key, $value ) = split( /\=/, $pair );
        $args{$key} = $value || 0;
    }
    $r->log->debug( "args string: " . $r->args );
    $r->log->debug( "args: " . Dumper( \%args ) );

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
    unless ( $router->wan_ip eq $ip ) {
        $router->wan_ip($ip);
    }

    # update the latest seen users
    $router->clients( $args{users} );

    # gateway or repeater?
    if (defined $args{role} && $args{role} eq 'G') {
      $router->gateway(1);
    } elsif (defined $args{role} && $args{role} eq 'R') {
      $router->gateway(0);
    } else {
      $router->gateway(1);
    }

    # repeater stuff
    if (!$router->gateway) {
        my $gwip = $args{routes};
        my ($gateway) = SL::Model::App->resultset('Router')->search({ip => $gwip });

        $router->speed_test(sprintf("%d hops, %d ms ping and %s to gateway %s",
                                $args{hops}, $args{RTT}, $args{NTR}, $gateway->name));

    } else {

        $router->speed_test(sprintf("%d neighbors in range", scalar(split(/\;/, $args{nbs}))));
    }

    $router->update;

    # log the router entry
    my $checkin = SL::Model::App->resultset('Checkin')->create(
        {
            router_id => $router->router_id,
            memfree   => $args{memfree},
            users     => $args{users},
            kbup      => $args{kbup},
            kbdown    => $args{kbdown},
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

1;
