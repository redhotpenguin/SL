package SL::Map;

use strict;
use warnings;

use SL::Model::App;
use HTML::GoogleMaps;

our $VERSION = 0.01;

use SL::Config;

our $config = SL::Config->new;

#our $Apikey =
#'ABQIAAAAyhXzbW_tBTVZ2gviL0TQQxQy1V7Lnb51SK2Zw6jkMdSNmKWG4BR6rYy1O4_e1HE-uzbTquoRsEEKfA';

our $Apikey =
'ABQIAAAAyhXzbW_tBTVZ2gviL0TQQxRi_j0U6kJrkFvY4-OX2XYmEAa76BTkEv0Qcl179SXVx74OLXrE8yxRqw';

sub map {
    my ( $class, $args ) = @_;

    my $account = $args->{account} || die 'no account id passed';

    my @routers = SL::Model::App->resultset('Router')->search(
        { account_id => $account->account_id, active => 't' },
        { -order_by  => 'mts DESC' },
    );

    my $map = HTML::GoogleMaps->new(
        height => 600,
        width  => 800,
        key    => $Apikey
    );

    $map->map_id("Map1");
    $map->map_type("normal");
    $map->v2_zoom(15);
    $map->center(94109);
    $map->info_window(1);
    my $icon_base =
        'http://127.0.0.1:8887/'
      . $config->sl_app_base_uri
      . '/resources/images/icons/maps/';
    $map->controls( 'large_map_control', 'map_type_control' );

    # add repeater icon

    #        shadow             => $icon_base . '0_active.png',
    #        shadow_size        => [ G0, 0 ],

    foreach my $type (qw( active alerting trouble inactive )) {

        my $icon   = $icon_base . "0_$type.png";
        my $shadow = $icon_base . 'shadow_small_repeater.png';
        warn("icon $icon");
        $map->add_icon(
            shadow             => $shadow,
            shadow_size        => [ 20, 20 ],
            icon_anchor        => [ 0, 0 ],
            info_window_anchor => [ 0, 0 ],
            name               => $type,
            image              => $icon,
            image_size         => [ 20, 20 ]
        );

    }

    my $now = DateTime->now;
    $now->set_time_zone('local');
    foreach my $router (@routers) {

        next unless $router->lat && $router->lng;

        my $name = $router->name || 'noname';
        my $html = <<'HTML';
<a href="/%s/app/router/edit/?router_id=%d">%s</a>
HTML

        $html =
          sprintf( $html, $config->sl_app_base_uri, $router->router_id, $name );
        chomp($html);

        my $dt = DateTime::Format::Pg->parse_datetime( $router->last_ping );

        my $type;
        if ( DateTime->compare( $dt->add( minutes => 6 ), $now ) == 1 ) {

            $type = 'active';

        }
        elsif ( DateTime->compare( $dt->add( hours => 1 ), $now ) == 1 ) {
            $type = 'alerting';

        }
        elsif ( DateTime->compare( $dt->add( hours => 24 ), $now ) == 1 ) {
            $type = 'trouble';

        }
        else {

            $type = 'inactive';

        }

        $map->add_marker(
            point => [ $router->lng, $router->lat ],
            html  => $html,
            icon  => $type,
        );
    }

    my ( $head, $stuff ) = $map->onload_render;

    return ( $head, $stuff );
}
