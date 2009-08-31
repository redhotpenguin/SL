package SL::Map;

use strict;
use warnings;

use SL::Model::App;
use HTML::GoogleMaps;
use Data::Dumper;

use constant DEBUG         => $ENV{SL_DEBUG} || 0;
use constant VERBOSE_DEBUG => $ENV{SL_VERBOSE_DEBUG} || 0;

our $VERSION = 0.01;

use SL::Config;

our $Config = SL::Config->new;

# production key, add on rollout
#our $Apikey =
#'ABQIAAAAyhXzbW_tBTVZ2gviL0TQQxQy1V7Lnb51SK2Zw6jkMdSNmKWG4BR6rYy1O4_e1HE-uzbTquoRsEEKfA';

#our $Apikey = $Config->sl_gmap_apikey
our $Apikey =
   'ABQIAAAAyhXzbW_tBTVZ2gviL0TQQxRi_j0U6kJrkFvY4-OX2XYmEAa76BTkEv0Qcl179SXVx74OLXrE8yxRqw';
# || 'ABQIAAAAyhXzbW_tBTVZ2gviL0TQQxQy1V7Lnb51SK2Zw6jkMdSNmKWG4BR6rYy1O4_e1HE-uzbTquoRsEEKfA';



# warn("apikey is $Apikey") if DEBUG;

sub map {
    my ( $class, $args ) = @_;

    my $account = $args->{account} || die 'no account id passed';
    my $server_root = $args->{server_root} || die 'no server root';

    my $routers = $account->get_routers;

    my $map = HTML::GoogleMaps->new(
        height => 600,
        width  => 800,
        key    => $Apikey
    );

    $map->map_id( $account->name );
    $map->map_type("normal");
    $map->v2_zoom( $account->map_zoom );
    $map->center( $account->map_center );
    $map->info_window(1);
    $map->controls( 'large_map_control', 'map_type_control' );
    my $icon_base =
        $server_root
      . $Config->sl_app_base_uri
      . '/resources/images/icons/maps/';

    warn(
        sprintf(
            "icon base %s, zoom %s, center %s",
            $icon_base, $account->map_zoom, $account->map_center
        )
    ) if DEBUG;

    # add router icons
    my $shadow = $icon_base . 'shadow_small_repeater.png';

=cut

    foreach my $type (qw( active alerting trouble inactive )) {
        foreach my $idx ( 0 .. 10 ) {
            foreach my $icon ( "$idx\_$type", "$idx\_gateway\_$type" ) {

                $map->add_icon(
                    shadow             => $shadow,
                    shadow_size        => [ 20, 20 ],
                    icon_anchor        => [ 0, 0 ],
                    info_window_anchor => [ 0, 0 ],
                    name               => $icon,
                    image              => $icon_base . $icon . '.png',
                    image_size         => [ 20, 20 ]
                );

            }
        }
    }
=cut

    # now put the devices on the map
    my $now = DateTime->now;
    $now->set_time_zone('local');
    my @misconfigured;
    my %icons_added;
    my ($total_nodes, $problem_nodes, $inactive_nodes) = (0,0,0);
    foreach my $router (@$routers) {

        # improperly configured devices
        unless ($router->lat && $router->lng) {
            push @misconfigured, $router->id;
            next;
        }


        # FIXME - replace this with a template
        my $name = $router->name || 'noname';
        my $html = <<'HTML';
<strong>Device:</strong>  <a href="/%s/app/router/edit/?router_id=%d">%s</a><br /><strong>Users Last 24 hours:</strong>  %s<br /><strong>Traffic Last 24 hours:</strong>  %s<br /><strong>Last Seen:</strong>  %s<br />WAN IP:  %s<br /><strong>LAN IP:</strong>  %s<br /><strong>Mac Address:</strong>  %s<br /><strong>Device IP:</strong>  %s
HTML

        $html =
          sprintf( $html,
                   $Config->sl_app_base_uri,
                   $router->router_id,
                   $name,
                   $router->users_daily,
                   $router->traffic_daily,
                   $router->wan_ip,
                   $router->lan_ip,
                   $router->macaddr,
                   $router->ip,);

        chomp($html);

        my $dt = DateTime::Format::Pg->parse_datetime( $router->last_ping );

        my $type;
        if ( DateTime->compare( $dt->add( minutes => 6 ), $now ) == 1 ) {

            $type = 'active';

        }
        elsif ( DateTime->compare( $dt->add( hours => 1 ), $now ) == 1 ) {
            $type = 'alerting';
            $problem_nodes++;
        }
        elsif ( DateTime->compare( $dt->add( hours => 24 ), $now ) == 1 ) {
            $type = 'trouble';
            $problem_nodes++;
        }
        else {

            $type = 'inactive';
            $inactive_nodes++;
        }

        my $icon = ($router->users_daily > 10) ? 10 : $router->users_daily;
        if ($router->gateway) {

            # gateways
            $icon .= '_gateway';
        }

        # add the type (inactive, etc)
        $icon .= "_$type";

        unless ($icons_added{$icon}) {

            my %icon_args = (
                    shadow             => $shadow,
                    shadow_size        => [ 20, 20 ],
                    icon_anchor        => [ 0, 0 ],
                    info_window_anchor => [ 0, 0 ],
                    name               => $icon,
                    image              => $icon_base . $icon . '.png',
                    image_size         => [ 20, 20 ]
            );

            warn(sprintf("adding icon args %s", Dumper(\%icon_args))) if DEBUG;
            $map->add_icon(%icon_args);
        }

        my %marker_args = (
            point => [ $router->lng, $router->lat ],
            html  => $html,
            icon  => $icon,
         );

        $map->add_marker( %marker_args );

        warn(sprintf("placed router %d with args %s",
                     $router->router_id, Dumper(\%marker_args))) if DEBUG;

            $total_nodes++;

    }

    if (@misconfigured) {
      warn(sprintf("devices missing lat && lng: %s",
                   join(',', @misconfigured)));
    }

    my ( $head, $stuff ) = $map->onload_render;

    unless ($head && $stuff) {
      die "error creating map";
    }

    warn("map head: $head") if VERBOSE_DEBUG;
    warn("map stuff: $stuff") if VERBOSE_DEBUG;

    return ( $head, $stuff, $total_nodes, $problem_nodes, $inactive_nodes  );
}

1;
