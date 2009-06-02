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
        my $doc    = $parser->parse_string( $response->decoded_content );

        my @nodes = $doc->getElementsByTagName('node');
        my @router_data;

        foreach my $node (@nodes) {
            my %router;
            $router{name} = $node->getChildrenByTagName('name')->string_value;
            $router{mac}  = $node->getChildrenByTagName('mac')->string_value;
            $router{lat} =  $node->getChildrenByTagName('lat')->string_value;
            $router{lng} =  $node->getChildrenByTagName('lng')->string_value;
            $router{ip} = $node->getChildrenByTagName('ip')->string_value;

            $router{notes} =
              $node->getChildrenByTagName('notes')->string_value;
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
                unless ( $router->account_id->account_id ==
                    $reg->account_id->account_id )
                {

                    $steal++;

                    # someone else has the router, steal it
                    $r->log->error(
                        sprintf(
                            "account %s stealing router %s from %s",
                            $reg->account_id->name, $router->macaddr,
                            $router->account_id->name,
                        )
                    );
                    $router->account_id( $reg->account_id->account_id );
                }

                if   ( $steal == 0 ) { $updated++ }
                else                 { $created++ }

            }
            else {

                # new router, create it
                $router =
                  SL::Model::App->resultset('Router')
                  ->create( { macaddr => $router_datum->{mac}, } );
                $router->account_id( $reg->account_id->account_id );
                $router->device('mr3201a');
                $created++;
            }

            $router->name( $router_datum->{name} );
            $router->active(1);
            $router->lat($router_datum->{lat});
            $router->lng($router_datum->{lng});
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
          ->search( { account_id => $reg->account_id->account_id } );

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

    # ad zones for this account
    my @ad_zones = $reg->get_ad_zones;

    my @only_ads = grep { !$_->hidden } @ad_zones;

    my ($twit_zone) = grep { $_->name eq '_twitter_feed' } @ad_zones;
    my ($msg_zone)  = grep { $_->name eq '_message_bar' } @ad_zones;

    my ( %router__ad_zones, @locations, $router, $output );
    if ( $req->param('router_id') ) {    # edit existing router

        ($router) = SL::Model::App->resultset('Router')->search(
            {
                account_id => $reg->account_id->account_id,
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
          map  { $_->location_id } $router->router__locations;

        # current associations for this router, including twitter
        %router__ad_zones =
          map { $_->ad_zone_id->ad_zone_id => 1 } $router->router__ad_zones;

        foreach my $ad_zone (@only_ads) {
            if ( exists $router__ad_zones{ $ad_zone->ad_zone_id } ) {
                $ad_zone->{selected} = 1;
            }

        }

        if ($twit_zone) {
            if ( exists $router__ad_zones{ $twit_zone->ad_zone_id } ) {
                $twit_zone->{selected} = 1;
            }
        }

        if ($msg_zone) {
            if ( exists $router__ad_zones{ $msg_zone->ad_zone_id } ) {
                $msg_zone->{selected} = 1;
            }
        }

    }

    if ( $r->method_number == Apache2::Const::M_GET ) {
        my %tmpl_data = (
            twit_zone => $twit_zone,
            msg_zone  => $msg_zone,
            ad_zones  => \@only_ads,
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
                    $reg->email, $macaddr, $router->account_id->name
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
        $router->account_id( $reg->account_id->account_id );
        $router->update;
    }

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

    # and update the associated ad zones for this router
    # first get rid of the old associations
    SL::Model::App->resultset('RouterAdZone')
      ->search( { router_id => $router->router_id } )->delete_all;

    # handle twitter feed
    if ( $req->param('zone_type') eq 'twitter' ) {

        SL::Model::App->resultset('RouterAdZone')->find_or_create(
            {
                router_id  => $router->router_id,
                ad_zone_id => $twit_zone->ad_zone_id,
            }
        );

    }
    elsif ( $req->param('zone_type') eq 'msg' ) {

        SL::Model::App->resultset('RouterAdZone')->find_or_create(
            {
                router_id  => $router->router_id,
                ad_zone_id => $msg_zone->ad_zone_id,
            }
        );

    }
    elsif ( $req->param('zone_type') eq 'iab' ) {

        # for ad zones
        foreach my $ad_zone_id ( $req->param('ad_zone') ) {
            $r->log->debug("$$ associating router with ad zone $ad_zone_id")
              if DEBUG;
            SL::Model::App->resultset('RouterAdZone')->find_or_create(
                {
                    router_id  => $router->router_id,
                    ad_zone_id => $ad_zone_id,
                }
            );
        }

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
          ( time - $dt->epoch - 3600 * 7 ); # FIXME daylight savings time breaks
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
      sort { $b->views_daily <=> $a->views_daily }
      sort { $a->{'seen_index'} <=> $b->{'seen_index'} }
      sort { $a->{'last_seen'} cmp $b->{'last_seen'} } @routers;

    my %tmpl_data = (
        session => $r->pnotes('session'),
        routers => \@routers,
        count   => scalar(@routers),
    );

    my $output;
    $Tmpl->process( 'router/list.tmpl', \%tmpl_data, \$output, $r )
      || return $class->error( $r, $Tmpl->error );

    return $class->ok( $r, $output );
}

1;
