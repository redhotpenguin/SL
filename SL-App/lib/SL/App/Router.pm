package SL::App::Router;

use strict;
use warnings;

use Apache2::Const -compile => qw(OK SERVER_ERROR NOT_FOUND M_GET M_POST);
use Apache2::Log        ();
use Apache2::SubRequest ();
use Apache2::Request    ();
use Apache2::SubRequest ();
use Data::FormValidator ();
use XML::LibXML         ();
use HTML::GoogleMaps    ();
use Data::Dumper;

use base 'SL::App';

use SL::Model;
use SL::Model::App;    # works for now
use SL::App::Template ();
use SL::Config;

our $Config = SL::Config->new;

our $Tmpl = SL::App::Template->template();

use constant DEBUG         => $ENV{SL_DEBUG}         || 0;
use constant VERBOSE_DEBUG => $ENV{SL_VERBOSE_DEBUG} || 0;

our $Apikey = $Config->sl_gmap_key ||  'ABQIAAAAyhXzbW_tBTVZ2gviL0TQQxTsWgBucG0c8uJlOLWh0_T9Sta0kxTxDDSstcYwd8oHy5R96NYHd07KFA';

# production key, add on rollout
#'ABQIAAAAyhXzbW_tBTVZ2gviL0TQQxQy1V7Lnb51SK2Zw6jkMdSNmKWG4BR6rYy1O4_e1HE-uzbTquoRsEEKfA';

# 192.168.1.121
#'ABQIAAAAyhXzbW_tBTVZ2gviL0TQQxTsWgBucG0c8uJlOLWh0_T9Sta0kxTxDDSstcYwd8oHy5R96NYHd07KFA';

# 127.0.0.1
#'ABQIAAAAyhXzbW_tBTVZ2gviL0TQQxRGsjeT8YPG8Wf95T-lVG33bp2K-xSOp0qPQkb8Yz7_cDoTISsnM3UrLg';

# test iMac
# 24.23.174.103
#'ABQIAAAAyhXzbW_tBTVZ2gviL0TQQxSg_ULh7M3_G5UrPi2z6bAJSsaYCBTAhApwkxdrjMZLFtjQMIII-pzzlQ';



sub dispatch_history {
    my ( $class, $r ) = @_;

    my $reg = $r->pnotes( $r->user );

    return Apache2::Const::NOT_FOUND if !$reg->account->beta;

    my %tmpl_data = ( account => $reg->account );
    my $account  = $reg->account;

    my $filename = join( '/',
        $account->report_dir_base,
        "network_monthly.csv" );

    unless (-e $filename) {
	my $fh;
        open($fh, '>', $filename) or die $!;
	print $fh '0,0,0,0';
        close $fh or die $!;
    }

    %tmpl_data = (
        network_history => $filename,
        %tmpl_data
    );

    my $output;
    $Tmpl->process( 'router/history.tmpl', \%tmpl_data, \$output, $r )
      || return $class->error( $r, "Template error: " . $Tmpl->error );
    return $class->ok( $r, $output );
}





sub dispatch_index {
    my ( $class, $r ) = @_;

    my $reg = $r->pnotes( $r->user );

    return Apache2::Const::NOT_FOUND if !$reg->account->beta;

    my %tmpl_data = ( account => $reg->account );
    my $server_root = (DEBUG) ? $r->construct_url('') :
	'https://' . $Config->sl_app_servername;

    my ( $head, $map, $total, $trouble, $inactive ) = eval {
        $class->map(
            $r,
            {   account     => $reg->account,
                server_root => $server_root,
            }
        );
    };

    if ( $@ or ( !$head && !$map ) ) {

        # handle map errors
        $r->log->error("Error generating map: $@");
        $tmpl_data{map_error} = 1;
    }
    else {
        %tmpl_data = ( head => $head, map => $map, %tmpl_data );
    }

    my $account  = $reg->account;

    my $filename = join( '/',
        $account->report_dir_base,
        "network_overview.csv" );

    unless (-e $filename) {
	my $fh;
        open($fh, '>', $filename) or die $!;
	print $fh '0,0,0,0';
        close $fh or die $!;
    }


    %tmpl_data = (
        active_nodes     => $total,
        problem_nodes    => $trouble,
        inactive_nodes   => $inactive,
        network_overview => $filename,
        %tmpl_data
    );

    my $output;
    $Tmpl->process( 'router/index.tmpl', \%tmpl_data, \$output, $r )
      || return $class->error( $r, "Template error: " . $Tmpl->error );
    return $class->ok( $r, $output );
}

sub dispatch_omsync {
    my ( $class, $r, $args_ref ) = @_;

    my $req = $args_ref->{req} || Apache2::Request->new($r);
    my $reg = $r->pnotes( $r->user );

    my $new = $req->param('network');

    if ( $r->method_number == Apache2::Const::M_GET ) {
        my %tmpl_data = (
            errors => $args_ref->{errors},
            req    => $req,
            reg    => $reg,
        );

        my $output;
        $Tmpl->process( 'router/omsync.tmpl', \%tmpl_data, \$output, $r )
          || return $class->error( $r, $Tmpl->error );

        return $class->ok( $r, $output );
    }
    elsif ( $r->method_number == Apache2::Const::M_POST ) {

        # reset method to get for redirect
        $r->method_number(Apache2::Const::M_GET);

        my %profile = ( required => [qw( network password )], );
        my $results = Data::FormValidator->check( $req, \%profile );

        # handle form errors
        if ( $results->has_missing or $results->has_invalid ) {
            my $errors = $class->SUPER::_results_to_errors($results);
            return $class->dispatch_omsync(
                $r,
                {
                    errors => $errors,
                    req    => $req
                }
            );
        }

        my $om_url =
          eval { URI->new('http://www.open-mesh.com/export_nodes.php') };
        if ($@) {
            $r->log->error("invalid om url");
            return Apache2::Const::SERVER_ERROR;
        }

        my $response = eval {
            $class->ua->post(
                $om_url,
                {
                    network => $req->param('network'),
                    passwd  => $req->param('password')
                }
            );
        };
        if ($@) {
            $r->log->error("invalid om url");
            return Apache2::Const::SERVER_ERROR;
        }

        if ( length( $response->decoded_content ) == 0 ) {

            # bad net/pass
            my %errors;
            $errors{invalid}{network}  = 1;
            $errors{invalid}{password} = 1;
            return $class->dispatch_omsync(
                $r,
                {
                    errors => \%errors,
                    req    => $req
                }
            );
        }

        # parse the router xml
        my $parser = XML::LibXML->new;
        my $doc = eval { $parser->parse_string( $response->decoded_content ); };
        if ($@) {

            $r->log->error( "open-mesh.com call network error for net "
                  . $req->param('network') );

            $r->log->error( "response: " . $response->decoded_content );

            return $class->dispatch_omsync(
                $r,
                {
                    errors => { sync => 1 },
                    req    => $req
                }
            );
        }

        my @nodes = $doc->getElementsByTagName('node');
        my @router_data;

        foreach my $node (@nodes) {
            my %router;
            $router{name} = $node->getChildrenByTagName('name')->string_value;
            $router{mac}  = $node->getChildrenByTagName('mac')->string_value;
            $router{lat}  = $node->getChildrenByTagName('lat')->string_value;
            $router{lng}  = $node->getChildrenByTagName('lng')->string_value;
            $router{ip}   = $node->getChildrenByTagName('ip')->string_value;

            $router{notes} = $node->getChildrenByTagName('notes')->string_value;
            push @router_data, \%router;
        }

        my ( $updated, $created ) = ( 0, 0 );
        foreach my $router_datum (@router_data) {

            my ($router) =
              SL::Model::App->resultset('Router')
              ->search( { macaddr => $router_datum->{mac}, } );

            if ($router) {

                # router already exists
                my $steal = 0;
                unless (
                    $router->account->account_id == $reg->account->account_id )
                {

                    $steal++;

                    # someone else has the router, steal it
                    $r->log->error(
                        sprintf(
                            "account %s stealing router %s from %s",
                            $reg->account->name, $router->macaddr,
                            $router->account->name,
                        )
                    );
                    $router->account_id( $reg->account->account_id );
                }

                if   ( $steal == 0 ) { $updated++ }
                else                 { $created++ }

            }
            else {

                # new router, create it
                $router =
                  SL::Model::App->resultset('Router')
                  ->create( { macaddr => $router_datum->{mac}, } );
                $router->account_id( $reg->account->account_id );
                $router->device('mr3201a');
                $created++;
            }

            $router->name( $router_datum->{name} );
            $router->active(1);
            $router->lat( $router_datum->{lat} );
            $router->lng( $router_datum->{lng} );
            $router->ip( $router_datum->{ip} );
            $router->notes( $router_datum->{notes} );
            $router->adserving(1);
            $router->update;

        }

        $r->pnotes('session')->{msg} = sprintf(
"Open-Mesh.com Network '%s' Sync complete, %s routers added, %s routers updated",
            $req->param('network'),
            $created, $updated
        );

        $r->headers_out->set(
            Location => $r->construct_url('/app/router/list') );
        return Apache2::Const::REDIRECT;
    }

}

sub dispatch_adbar {
    my ( $class, $r, $args_ref ) = @_;

    my $req = $args_ref->{req} || Apache2::Request->new($r);
    my $reg = $r->pnotes( $r->user );

    my $ab = $req->param('adbar');

    if ( $r->method_number == Apache2::Const::M_GET ) {
        my %tmpl_data = (
            errors => $args_ref->{errors},
            req    => $req,
            reg    => $reg,
        );

        my $output;
        $Tmpl->process( 'router/adbar.tmpl', \%tmpl_data, \$output, $r )
          || return $class->error( $r, $Tmpl->error );

        return $class->ok( $r, $output );
    }
    elsif ( $r->method_number == Apache2::Const::M_POST ) {

        # reset method to get for redirect
        $r->method_number(Apache2::Const::M_GET);
        my %profile = ( required => [qw( adbar )], );
        my $results = Data::FormValidator->check( $req, \%profile );

        # handle form errors
        if ( $results->has_missing or $results->has_invalid ) {
            my $errors = $class->SUPER::_results_to_errors($results);
            return $class->dispatch_adbar(
                $r,
                {
                    errors => $errors,
                    req    => $req
                }
            );
        }

        my @routers =
          SL::Model::App->resultset('Router')
          ->search( { account_id => $reg->account->account_id } );

        my $changed = 0;
        foreach my $router (@routers) {

            my $update = ( $router->adserving == 1 ) ? 't' : 'f';
            if ( $update ne $req->param('adbar') ) {

                $router->adserving( $req->param('adbar') );
                $router->update;
                $changed++;
            }
        }

        my $status = ( $req->param('adbar') eq 't' ) ? 'On' : 'Off';

        $r->pnotes('session')->{msg} =
          sprintf( "Ad Serving was set to %s for %d routers",
            $status, $changed );

        $r->headers_out->set(
            Location => $r->construct_url('/app/router/list') );
        return Apache2::Const::REDIRECT;
    }
}

sub dispatch_edit {
    my ( $class, $r, $args_ref ) = @_;

    my $req = $args_ref->{req} || Apache2::Request->new($r);
    my $reg = $r->pnotes( $r->user );

    my $zone_type = $reg->account->zone_type;

    ##################################
    # for banner ads only
    my ( @pzones, @bzones );
    if ( $zone_type eq 'banner_ad' ) {

        # persistent zones
        @pzones = $reg->get_persistent_zones;
        $r->log->debug( "pzones " . join( "\n", map { $_->name } @pzones ) )
          if DEBUG;

        # branding images
        @bzones = $reg->get_branding_zones;

        $r->log->debug( "bzones " . join( "\n", map { $_->name } @bzones ) )
          if DEBUG;
    }

    # splash page
    my @szones = $reg->get_splash_zones;

    $r->log->debug( "got szones " . join( "\n", map { $_->name } @szones ) )
      if DEBUG;

    my ( %router__ad_zones, @locations, $router, $output );
    if ( $req->param('router_id') ) {    # edit existing router

        ($router) = SL::Model::App->resultset('Router')->search(
            {
                account_id => $reg->account->account_id,
                router_id  => $req->param('router_id'),
            }
        );

        unless ($router) {
            $r->log->error(
                sprintf(
                    "unauthorized access, router %s, reg %s",
                    $req->param('router_id'),
                    $reg->reg_id
                )
            );
            return Apache2::Const::NOT_FOUND;
        }

        # get the locations for the router
        @locations =
          sort { $b->mts cmp $a->mts }
          map  { $_->location } $router->router__locations;

        # format the time
        $_->mts( $class->sldatetime( $_->mts ) ) for @locations;

        # current associations for this router, including twitter
        %router__ad_zones =
          map { $_->ad_zone->ad_zone_id => 1 } $router->router__ad_zones;

        foreach my $ad_zone ( @pzones, @szones, @bzones ) {
            if ( exists $router__ad_zones{ $ad_zone->ad_zone_id } ) {
                $ad_zone->{selected} = 1;
            }

        }

    }


    if ( $r->method_number == Apache2::Const::M_GET ) {

	my $router_id = $router->router_id;

    my $filename = join( '/',
        $reg->account->report_dir_base,
        "router_$router_id\_connectivity.csv" );

    unless (-e $filename) {
	my $fh;
        open($fh, '>', $filename) or die $!;
	print $fh '0,0';
        close $fh or die $!;
    }

    $filename = join( '/',
        $reg->account->report_dir_base,
        "router_$router_id\_ping.csv" );

    unless (-e $filename) {
	my $fh;
        open($fh, '>', $filename) or die $!;
	print $fh '0,0,0';
        close $fh or die $!;
    }


    $filename = join( '/',
        $reg->account->report_dir_base,
        "router_$router_id\_traffic.csv" );

    unless (-e $filename) {
	my $fh;
        open($fh, '>', $filename) or die $!;
	print $fh '0,0,0,0';
        close $fh or die $!;
    }




        my %tmpl_data = (
            ad_zones  => \@pzones,
            szones    => \@szones,
            bzones    => \@bzones,
            router    => $router,
            locations => scalar( @locations > 0 ) ? \@locations : '',
            errors    => $args_ref->{errors},
            req       => $req,
        );

        $Tmpl->process( 'router/edit.tmpl', \%tmpl_data, \$output, $r )
          || return $class->error( $r, $Tmpl->error );

        return $class->ok( $r, $output );
    }
    elsif ( $r->method_number == Apache2::Const::M_POST ) {

        # reset method to get for redirect
        $r->method_number(Apache2::Const::M_GET);

        my @required = qw( device macaddr name );

        my %router_profile = (
            required => \@required,
            optional => [
                qw( splash_href splash_timeout notes
                  ssid serial_number )
            ],
            constraint_methods => {
                serial_number => $class->valid_serial(),
                macaddr       => $class->valid_mac(),
                splash_href   => $class->splash_href(),
            }
        );
        my $results = Data::FormValidator->check( $req, \%router_profile );

        # handle form errors
        if ( $results->has_missing or $results->has_invalid ) {
            my $errors = $class->SUPER::_results_to_errors($results);
            return $class->dispatch_edit(
                $r,
                {
                    errors => $errors,
                    req    => $req
                }
            );
        }
    }

    my $macaddr = $req->param('macaddr');

    unless ($router) {

        # adding a new router
        ($router) =
          SL::Model::App->resultset('Router')
          ->search( { macaddr => $macaddr, } );

        if ($router) {

            # we are stealing it from somewhere
            $r->log->error(
                sprintf(
                    'user %s stealing router %s from account %s',
                    $reg->email, $macaddr, $router->account->name
                )
            );
        }
        else {

            # creating a new router
            $router =
              SL::Model::App->resultset('Router')
              ->create( { macaddr => $macaddr } );
        }

        foreach my $param qw( name splash_href notes
          serial_number ssid splash_timeout ) {
            $router->$param( $req->param($param) );
          } $router->active(1);
        $router->account_id( $reg->account->account_id );
        $router->update;
    }

    # macaddress
    $router->macaddr($macaddr);

    $router->name( $req->param('name') );

    # create an ssid event if the ssid changed
    if ( $router->device eq 'wrt54gl' ) {
        if ( defined $router->ssid
            && ( $router->ssid ne $req->param('ssid') ) )
        {
            $router->ssid_event( $req->param('ssid') );
        }

        # update each attribute
        foreach my $param qw( name splash_href device
          serial_number ssid splash_timeout ) {
            $router->$param( $req->param($param) );
          };
        $router->active(1);
    }

    # active?  adserving?
    $router->$_( $req->param($_) ) for qw( active adserving );

    $router->update;

    if ( $reg->account->zone_type eq 'banner_ad' ) {

        # and update the associated ad zones for this router
        # first get rid of the old associations
        SL::Model::App->resultset('RouterAdZone')
          ->search( { router_id => $router->router_id } )->delete_all;

        # for ad zones
        foreach my $ad_zone_id ( $req->param('ad_zone') ) {

            $r->log->debug("associating router with ad zone $ad_zone_id")
              if DEBUG;
            SL::Model::App->resultset('RouterAdZone')->create(
                {
                    router_id  => $router->router_id,
                    ad_zone_id => $ad_zone_id,
                }
            );
        }

        # handle branding images
        if ( $reg->account->plan ne 'free' ) {

            # branding images
            foreach my $ad_zone_id ( $req->param('branding_zone') ) {
                $r->log->debug(
                    "associating router with branding zone $ad_zone_id")
                  if DEBUG;
                SL::Model::App->resultset('RouterAdZone')->create(
                    {
                        router_id  => $router->router_id,
                        ad_zone_id => $ad_zone_id,
                    }
                );
            }
        }
        elsif ( $reg->account->plan eq 'free' ) {

            # look for an appropriate size image
            my ($bi) = SL::Model::App->resultset('AdZone')->search(
                {
                    account_id => $reg->account_id,
                    ad_size_id => { -in => [qw( 21 22 )] },
                }
            );

            unless ($bi) {

                $bi = SL::Model::App->resultset('AdZone')->create(
                    {
                        reg_id     => $reg->reg_id,
                        account_id => $reg->account_id,
                        ad_size_id => 21,
                        name       => 'Default Branding Image',
                        image_href =>
'http://s1.slwifi.com/images/ads/sln/leaderboard_sponsored_by.gif',
                        link_href =>
'http://www.silverliningnetworks.com/?referer=default_branding_image',
                        weight => 1,
                    }
                );

            }

            SL::Model::App->resultset('RouterAdZone')->create(
                {
                    router_id  => $router->router_id,
                    ad_zone_id => $bi->ad_zone_id,
                }
            );

        }

    }

    # assign the splash page ad
    foreach my $ad_zone_id ( $req->param('splash_zone') ) {

        $r->log->debug("associating router with splash zone $ad_zone_id")
          if DEBUG;

        SL::Model::App->resultset('RouterAdZone')->create(
            {
                router_id  => $router->router_id,
                ad_zone_id => $ad_zone_id,
            }
        );
    }

    my $status = $req->param('router_id') ? 'updated' : 'created';
    $r->pnotes('session')->{msg} =
      sprintf( "Router '%s' was %s", $router->name, $status );

    $r->headers_out->set( Location => $r->construct_url('/app/router/list') );
    return Apache2::Const::REDIRECT;
}

sub dispatch_list {
    my ( $class, $r, $args_ref ) = @_;

    my $reg = $r->pnotes( $r->user );
    my $req = Apache2::Request->new($r);

    my @routers = $reg->get_routers( $req->param('ad_zone_id') );

    foreach my $router (@routers) {

        my $dt = DateTime::Format::Pg->parse_datetime( $router->last_ping );

        # hack for pacific time
        my $sec =
          ( time - $dt->epoch - 3600 * 7 );   # FIX daylight savings time breaks

        my $minutes = sprintf( '%d', $sec / 60 );

        if ( $sec <= 360 ) {
            $router->{'last_seen'} =
              qq{<font color="green"><b>$sec sec</b></font>};
            $router->{'seen_index'} = 1;
        }
        elsif ( ( $sec > 360 ) && ( $minutes <= 60 ) ) {
            $router->{'last_seen'} =
              qq{<font color="red"><b>$minutes min</b></font>};
            $router->{'seen_index'} = 2;
        }
        elsif ( ( $minutes > 60 ) && ( $minutes < 1440 ) ) {
            my $hours = sprintf( '%d', $minutes / 60 );
            $router->{'last_seen'} =
              qq{<font color="orange"><b>$hours hours</b></font>};
            $router->{'seen_index'} = 3;
        }
        else {
            $router->{'last_seen'} =
                '<font color="black">'
              . sprintf( '%d', $minutes / 1440 ) . ' days'
              . '</font>';
            $router->{'seen_index'} = 4;
        }
    }

    @routers =
      sort { $a->{'seen_index'} <=> $b->{'seen_index'} }
      sort { $a->{'last_seen'} cmp $b->{'last_seen'} }
      sort { $b->views_daily <=> $a->views_daily } @routers;

    my %tmpl_data = (
        routers => \@routers,
        count   => scalar(@routers),
    );

    my $output;
    $Tmpl->process( 'router/list.tmpl', \%tmpl_data, \$output, $r )
      || return $class->error( $r, $Tmpl->error );

    return $class->ok( $r, $output );
}

sub dispatch_deactivate {
    my ( $class, $r, $args_ref ) = @_;

    my $reg = $r->pnotes( $r->user );
    my $req = Apache2::Request->new($r);

    my $id = $req->param('id');

    my ($router) = SL::Model::App->resultset('Router')->search(
        {
            account_id => $reg->account_id,
            router_id  => $id,
            active     => 't',
        }
    );

    return Apache2::Const::NOT_FOUND unless $router;

    $router->active(0);
    $router->update;

    $r->pnotes('session')->{msg} =
      sprintf( "Router '%s' was deleted", $router->name );
    $r->headers_out->set( Location => $r->headers_in->{'referer'} );
    return Apache2::Const::REDIRECT;
}

sub map {
    my ( $class, $r, $args ) = @_;

    my $account     = $args->{account}     || die 'no account id passed';
    my $server_root = $args->{server_root} || die 'no server root';

    my $routers = $account->get_routers;

    @{$routers} = grep { defined $_->lat && defined $_->lng } @{$routers};

    my $map = HTML::GoogleMaps->new(
        height => 600,
        width  => 940,
        key    => $Apikey
    );

    $map->map_id( $account->name );
    $map->map_type("normal");
    $map->v2_zoom( $account->map_zoom );
    $map->center( $account->map_center );
    $map->info_window(1);
    $map->controls( 'large_map_control', 'map_type_control' );
    my $icon_base =
      $server_root . $Config->sl_app_base_uri . '/resources/images/icons/maps/';

    $r->log->debug(
        sprintf(
            "icon base %s, zoom %s, center %s",
            $icon_base, $account->map_zoom, $account->map_center
        )
    ) if DEBUG;

    # add router icons
    my $shadow = $icon_base . 'shadow_small_repeater.png';

    # now put the devices on the map
    my $now = DateTime->now;
    $now->set_time_zone('local');
    my @misconfigured;
    my %icons_added;
    my ( $total_nodes, $problem_nodes, $inactive_nodes ) = ( 0, 0, 0 );
    foreach my $router (@$routers) {

        # improperly configured devices
        unless ( $router->lat && $router->lng ) {
            push @misconfigured, $router->id;
            next;
        }

        # get the latest checkin for this router
        my ($checkin) = SL::Model::App->resultset('Checkin')->search(
            { router_id => $router->router_id, },
            { order_by  => 'me.cts DESC' }
        );

        $r->log->debug( "grabbed last checkin: " . Dumper($checkin) )
          if DEBUG;

        my @neighbors;

        # skip if no neighbors
        if ( $checkin &&
                 (( $checkin->nodes ne 'z' ) or
                  ( $checkin->nodes_rssi ne 'z' ) ))
        {


	    my $nodes = $checkin->nodes;
            $nodes =~ s/(\%3b)/\;/g;
	    my @nodes = split( /\;/, $nodes );

	    my $rssis = $checkin->nodes_rssi;
            $rssis =~ s/(\%3b)/\;/g;
            my @rssis = split( /\;/, $rssis );

            $r->log->debug( "neighbors: " . Dumper( \@nodes ) ) if VERBOSE_DEBUG;

            foreach my $node (@nodes) {

                $r->log->debug("processing neighbor node $node")
                  if VERBOSE_DEBUG;

                my %args = ( account_id => $router->account_id );

                if ( substr( $node, 0, 2 ) eq '00' ) {

                    # $node is mac address
                    $args{macaddr} = $node;

                }
                else {

                    # node is ip
                    $args{ip} = $node;
                }
                my ($nbr) =
                  SL::Model::App->resultset('Router')->search( \%args );

                unless ($nbr) {
                    $r->log->warn("no device found for neighbor $node");
                    next;
                }

                $nbr->{rssi} = abs( shift(@rssis) );

                push @neighbors, $nbr;
            }
        }

        my %tmpl_data = ( router => $router, neighbors => \@neighbors );

        my $output;
        $Tmpl->process( 'map/info.tmpl', \%tmpl_data, \$output );

        my $neighbor_html;
        $Tmpl->process( 'map/neighbor.tmpl', \%tmpl_data, \$neighbor_html );

        # going to hell for this
        my $base_uri = $Config->sl_app_base_uri;
        my $report_base = $account->report_base;

=cut
        my $js = <<"JS";
		<script type="text/javascript" src="$base_uri/resources/chart/line/swfobject.js"></script>
	    <div id="flashcontent">
	        <strong>You need to upgrade your Flash Player</strong>
	    </div>
=cut

        my $js = <<"JS";
	    <script type="text/javascript">
	            // <![CDATA[
	            var so = new SWFObject("$base_uri/resources/chart/line/amline.swf","traffic", "580px", "250px", "4", "#FFFFFF");
	            so.addVariable("path", "$base_uri/resources/chart/line/");
	            so.addVariable("settings_file", encodeURIComponent("$base_uri/resources/chart/line/amline_settings.xml"));
	            so.addVariable("data_file", encodeURIComponent("$base_uri/img/reports/$report_base/network_overview.csv"));
	            so.write("flashcontent");
	            // ]]>
	    </script>
JS

        $js =~ s{([/#,.><()=![\];])}{\\$1}g;

        $r->log->debug("escaped js: " . $js) if DEBUG;

        my $ping_html;
        $Tmpl->process( 'map/ping_speed.tmpl',
                        { chartscript => $js, %tmpl_data }, \$ping_html );

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

        my $clients = ( $router->clients > 10 ) ? 10 : $router->clients;
        my $icon = $clients;
        if ( (defined $router->gateway && defined $router->wan_ip) && ($router->gateway eq $router->wan_ip) ) {

            # gateways
            $icon .= '_gateway';
        }

        # add the type (inactive, etc)
        $icon .= "_$type";

        unless ( $icons_added{$icon} ) {

            my $s = 20 + ( 1 * int($clients/2) );
            my %icon_args = (
                shadow             => $shadow,
                shadow_size        => [ $s, $s ],
                icon_anchor        => [ int($s/2), int($s/2) ],
                info_window_anchor => [ int($s/2), int($s/2) ],
                name               => $icon,
                image              => $icon_base . $icon . '.png',
                icon_size         => [ $s, $s ]
            );

            $r->log->debug( sprintf( "icon %s", Dumper( \%icon_args ) ) )
              if VERBOSE_DEBUG;
            $map->add_icon(%icon_args);
        }

        my %marker_args = (
            point         => [ $router->lng, $router->lat ],

            # this is out of control and must be stopped
            html          => $output,
            neighbor_html => $neighbor_html,
            ping_html     => $ping_html,


            icon          => $icon,
            title         => $router->name,
            mac           => $router->macaddr,
            board         => $router->board,
            ip            => $router->ip,
        );

        $map->add_marker(%marker_args);

	$r->log->debug("added marker for router_id " . Dumper(\%marker_args))
	    if DEBUG;

        # is this a repeater?  add a polyline to the gateway
        unless ( (defined $router->gateway && defined $router->wan_ip) && 
		 ($router->gateway eq $router->wan_ip ) ) {

            my ($gateway) =
              SL::Model::App->resultset('Router')
              ->search( { ip => $router->gateway } );

            $r->log->debug( "gateway is " . Dumper($gateway) ) if VERBOSE_DEBUG;

            unless ( $gateway && $gateway->lat && $gateway->lng ) {
                $r->log->warn(
                    "no gateway found for router " . $router->name );
            }
            else {

                $map->add_polyline(
                    weight => 10,
                    opacity => 1,
                    color => '\#000000',
                    points => [
                        [ $router->lng,  $router->lat ],
                        [ $gateway->lng, $gateway->lat ],
                    ]
                );
            }

        }

        $r->log->debug(
            sprintf(
                "placed router %d with args %s",
                $router->router_id, Dumper( \%marker_args )
            )
        ) if VERBOSE_DEBUG;

        $total_nodes++;

    }

    if (@misconfigured) {
        $r->log->warn(
            sprintf( "devices missing lat && lng: %s",
                join( ',', @misconfigured ) )
        );
    }

    my ( $head, $stuff ) = $map->onload_render;

    unless ( $head && $stuff ) {
        die "error creating map";
    }

    $r->log->debug("map head: $head")   if VERBOSE_DEBUG;
    $r->log->debug("map stuff: $stuff") if VERBOSE_DEBUG;

    return ( $head, $stuff, $total_nodes, $problem_nodes, $inactive_nodes );
}

1;
