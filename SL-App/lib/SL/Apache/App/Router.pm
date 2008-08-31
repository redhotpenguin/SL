package SL::Apache::App::Router;

use strict;
use warnings;

use Apache2::Const -compile => qw(OK SERVER_ERROR NOT_FOUND M_GET M_POST);
use Apache2::Log        ();
use Apache2::SubRequest ();
use Apache2::Request    ();
use Apache2::SubRequest ();

use Data::FormValidator ();

use base 'SL::Apache::App';

use SL::Model;
use SL::Model::App;    # works for now
use SL::App::Template ();

our $TMPL = SL::App::Template->template();

use constant DEBUG => $ENV{SL_DEBUG} || 0;

require Data::Dumper if DEBUG;

sub dispatch_index {
    my ( $self, $r ) = @_;

    my $output;
    my $ok = $TMPL->process( 'router/index.tmpl', {}, \$output, $r );

    return $self->ok( $r, $output ) if $ok;
    return $self->error( $r, "Template error: " . $TMPL->error() );
}

sub dispatch_edit {
    my ( $self, $r, $args_ref ) = @_;

    my $req = $args_ref->{req} || Apache2::Request->new($r);
    my $reg = $r->pnotes( $r->user );

    # ad zones for this account
    my @ad_zones =
      SL::Model::App->resultset('AdZone')
      ->search( { account_id => $reg->account_id->account_id } );

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
        @locations = map { $_->location_id } $router->router__locations;

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

        my $ok =
          $TMPL->process( 'router/edit.tmpl', \%tmpl_data, \$output, $r );
        
        return $self->ok( $r, $output ) if $ok;
        return $self->error( $r, "Template error: " . $TMPL->error() );
    }
    elsif ( $r->method_number == Apache2::Const::M_POST ) {

        # reset method to get for redirect
        $r->method_number(Apache2::Const::M_GET);
        my %router_profile = (
            required => [qw( name macaddr ssid serial_number )],
            optional => [qw( splash_href splash_timeout )],
            constraint_methods => {
                macaddr     => valid_macaddr(),
                splash_href => splash_href(),
            }
        );
        my $results = Data::FormValidator->check( $req, \%router_profile );

        # handle form errors
        if ( $results->has_missing or $results->has_invalid ) {
            my $errors = $self->SUPER::_results_to_errors($results);
            return $self->dispatch_edit(
                $r,
                {
                    errors => $errors,
                    req    => $req
                }
            );
        }
    }

    unless ($router) {

        # adding a new router
        $router = SL::Model::App->resultset('Router')->new(
            {
                active     => 't',
                account_id => $reg->account_id->account_id
            }
        );

      	foreach my $param qw( name macaddr splash_href
  	    serial_number ssid splash_timeout ) {
        	$router->$param( $req->param($param) );
     	}

	$router->insert;
        $router->update;
    } elsif ($router) {

    # create an ssid event if the ssid changed
    if ( defined $router->ssid && ( $router->ssid ne $req->param('ssid')  ) ) {
        $router->ssid_event( $req->param('ssid') );
    }

    # update each attribute
    foreach my $param qw( name macaddr splash_href
      serial_number ssid splash_timeout ) {
        $router->$param( $req->param($param) );
      }

      $router->update;
	}

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

sub dispatch_list {
    my ( $self, $r, $args_ref ) = @_;

    my $reg = $r->pnotes( $r->user );
    my $req = Apache2::Request->new($r);

    my @routers = $reg->get_routers( $req->param('ad_zone_id') );

    foreach my $router (@routers) {
        my $dt = DateTime::Format::Pg->parse_datetime( $router->last_ping );

        # hack for pacific time
        my $sec =
          ( time - $dt->epoch - 3600 * 7 ); # FIXME daylight savings time breaks
        my $minutes = sprintf( '%d', $sec / 60 );
        if ( $sec <= 60 ) {
            $router->{'last_seen'}  = "$sec sec";
            $router->{'seen_index'} = 1;
        }
        elsif ( ( $sec > 60 ) && ( $minutes <= 60 ) ) {
            $router->{'last_seen'}  = "$minutes min";
            $router->{'seen_index'} = 2;
        }
        elsif ( ( $minutes > 60 ) && ( $minutes < 1440 ) ) {
            my $hours = sprintf( '%d', $minutes / 60 );
            $router->{'last_seen'}  = "$hours hours";
            $router->{'seen_index'} = 3;
        }
        else {
            $router->{'last_seen'} = sprintf( '%d', $minutes / 1440 ) . ' days';
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
    my $ok = $TMPL->process( 'router/list.tmpl', \%tmpl_data, \$output, $r );
    $ok
      ? return $self->ok( $r, $output )
      : return $self->error( $r, "Template error: " . $TMPL->error() );
}

sub splash_timeout {
    return sub {
        my $dfv = shift;
        my $val = $dfv->get_current_constraint_value;
        return $val if ( $val =~ m/^\d{1,3}$/ );
        return;
      }
}

sub splash_href {
    return sub {
        my $dfv = shift;
        my $val = $dfv->get_current_constraint_value;

        return $val if ( $val =~ m/^https?:\/\/\w+/ );
        return;
      }
}

sub valid_macaddr {
    return sub {
        my $dfv = shift;
        my $val = $dfv->get_current_constraint_value;

        return $val if ( $val =~ m/^([0-9a-f]{2}([:-]|$)){6}$/i );
        return;
      }
}

1;
