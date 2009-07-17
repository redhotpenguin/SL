package SL::App::Router;

use strict;
use warnings;

use Apache2::Const -compile => qw(OK SERVER_ERROR NOT_FOUND M_GET M_POST);
use Apache2::Log        ();
use Apache2::SubRequest ();
use Apache2::Request    ();
use Apache2::SubRequest ();

use Data::FormValidator ();

use XML::LibXML ();

use base 'SL::App';

use SL::Model;
use SL::Model::App;    # works for now
use SL::App::Template ();

our $Tmpl = SL::App::Template->template();

use constant DEBUG => $ENV{SL_DEBUG} || 0;

use Data::Dumper;

sub dispatch_index {
    my ( $class, $r ) = @_;

    my $output;
    $Tmpl->process( 'router/index.tmpl', {}, \$output, $r )
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
        my $doc    = eval { $parser->parse_string(
                            $response->decoded_content ); };
        if ($@) {

          $r->log->error("open-mesh.com call network error for net " .
                         $req->param('network'));

          $r->log->error("response: " . $response->decoded_content);

          return $class->dispatch_omsync($r, { errors => { sync => 1 },
                                               req => $req } );
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
    my (@pzones, @bzones);
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

        my @required = qw( device macaddr );

        if ( $req->param('device') ne 'mr3201a' ) {
            push @required, 'name';
        }

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
          ( time - $dt->epoch - 3600 * 7 ); # FIX daylight savings time breaks
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

1;
