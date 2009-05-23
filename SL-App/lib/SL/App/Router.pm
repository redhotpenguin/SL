package SL::App::Router;

use strict;
use warnings;

use Apache2::Const -compile => qw(OK SERVER_ERROR NOT_FOUND M_GET M_POST);
use Apache2::Log        ();
use Apache2::SubRequest ();
use Apache2::Request    ();
use Apache2::SubRequest ();

use Data::FormValidator ();

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
    $Tmpl->process( 'router/index.tmpl', {}, \$output, $r ) ||
      return $class->error( $r, "Template error: " . $Tmpl->error );
    return $class->ok( $r, $output );
}

sub dispatch_edit {
    my ( $class, $r, $args_ref ) = @_;

    my $req = $args_ref->{req} || Apache2::Request->new($r);
    my $reg = $r->pnotes( $r->user );

    # ad zones for this account
    my @ad_zones = $reg->get_ad_zones;

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
        @locations = sort { $b->mts cmp $a->mts } map { $_->location_id } $router->router__locations;

        # current associations for this router
        %router__ad_zones =
          map { $_->ad_zone_id->ad_zone_id => 1 } $router->router__ad_zones;

        foreach my $ad_zone (@ad_zones) {
            if ( exists $router__ad_zones{ $ad_zone->ad_zone_id } ) {
                $ad_zone->{selected} = 1;
            }

        }
    }

    if ( $r->method_number == Apache2::Const::M_GET ) {
        my %tmpl_data = (
            ad_zones  => \@ad_zones,
            router    => $router,
            locations => scalar( @locations > 0 ) ? \@locations : '',
            errors    => $args_ref->{errors},
            req       => $req,
        );

        $Tmpl->process( 'router/edit.tmpl', \%tmpl_data, \$output, $r ) ||
          return $class->error( $r, $Tmpl->error);

        return $class->ok( $r, $output );
    }
    elsif ( $r->method_number == Apache2::Const::M_POST ) {

        # reset method to get for redirect
        $r->method_number(Apache2::Const::M_GET);

	my @required = qw( name  device macaddr );

        my %router_profile = (
            required => \@required,
            optional => [qw( splash_href splash_timeout
	    		     ssid serial_number )],
            constraint_methods => {
                serial_number     => $class->valid_serial(),
                macaddr           => $class->valid_mac(),
                splash_href       => $class->splash_href(),
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
#	if (substr(uc($macaddr), 0, 9) eq '00:12:CF:') {
	    # this is an open-mesh router
	    # translate the macaddress to ath1 format
	    # unless it is a bridge of course...
#	    my $is_a_gateway;
#	    if ($router) {
#	    	$is_a_gateway = $router->gateway;
#	    } else {
#	    	$is_a_gateway = 1;  # start as a gateway
#	    }
#	    $macaddr = om_mac__to__mac($macaddr, $is_a_gateway);
 #   }


    unless ($router) {
        # adding a new router
        ($router) = SL::Model::App->resultset('Router')->search(
            {
                macaddr => $macaddr,
            }
        );

	if ($router) {
	    # we are stealing it from somewhere
	    $r->log->error(
		sprintf('user %s stealing router %s from account %s',
		$reg->email, $macaddr, $router->account_id->name));
	} else {	
	    # creating a new router
	    $router = SL::Model::App->resultset('Router')->create(
	    	{macaddr => $macaddr });
	}

      	foreach my $param qw( name splash_href
	  	serial_number ssid splash_timeout ) {
        	$router->$param( $req->param($param) );
     	}
	$router->active(1);
	$router->account_id( $reg->account_id->account_id );
        $router->update;
    }

    # create an ssid event if the ssid changed
    if ( defined $router->ssid && ( $router->ssid ne $req->param('ssid')  ) ) {
        $router->ssid_event( $req->param('ssid') );
    }

    $router->macaddr($macaddr);
    # update each attribute
    foreach my $param qw( name splash_href device
      			serial_number ssid splash_timeout ) {
        $router->$param( $req->param($param) );
      }

    $router->update;

    # and update the associated ad zones for this router
    # first get rid of the old associations
    SL::Model::App->resultset('RouterAdZone')
      ->search( { router_id => $router->router_id } )->delete_all;

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

    my $status = $req->param('router_id') ? 'updated' : 'created';
    $r->pnotes('session')->{msg} =
      sprintf( "Router '%s' was %s", $router->name, $status );

    $r->headers_out->set(
        Location => $r->construct_url('/app/router/list') );
    return Apache2::Const::REDIRECT;
}

sub mac__to__om_mac {
	my $mac = shift or die 'no mac passed';
	my $gateway = shift;

	if (!$gateway) {
		# replace 00 with 06
		substr($mac,0,2,'06');
		return $mac;
	}

	my $last_two = substr($ mac, length($mac) - 2, length($mac));
	$last_two = sprintf('%02x', sprintf('%d', hex($last_two))-1);
	substr($mac, length($mac) - 2, length($mac), $last_two);
	substr($mac, 0, 2, '00');
	return $mac;
}

sub om_mac__to__mac {
	my $mac = shift or die 'no mac passed';
	my $gateway = shift;

	if (!$gateway) {
		# replace 06 with 00
		substr($mac,0,2,'00');
		return $mac;
	}

	my $last_two = substr($mac, length($mac) - 2, length($mac));
	$last_two = sprintf('%02x', sprintf('%d', hex($last_two))+1);
	substr($mac, length($mac) - 2, length($mac), $last_two);
	substr($mac, 0, 2, '06');
	return $mac;
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
          ( time - $dt->epoch - 3600 * 7); # FIXME daylight savings time breaks
        my $minutes = sprintf( '%d', $sec / 60 );
        if ( $sec <= 360 ) {
            $router->{'last_seen'}  = qq{<font color="green"><b>$sec sec</b></font>};
            $router->{'seen_index'} = 1;
        }
        elsif ( ( $sec > 360 ) && ( $minutes <= 60 ) ) {
            $router->{'last_seen'}  = qq{<font color="red"><b>$minutes min</b></font>};
            $router->{'seen_index'} = 2;
        }
        elsif ( ( $minutes > 60 ) && ( $minutes < 1440 ) ) {
            my $hours = sprintf( '%d', $minutes / 60 );
            $router->{'last_seen'}  = qq{<font color="orange"><b>$hours hours</b></font>};
            $router->{'seen_index'} = 3;
        }
        else {
            $router->{'last_seen'} = '<font color="black">' . sprintf( '%d', $minutes / 1440 ) . ' days' . '</font>';
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
    $Tmpl->process( 'router/list.tmpl', \%tmpl_data, \$output, $r ) ||
        return $class->error( $r, $Tmpl->error );

    return $class->ok( $r, $output );
}



1;
