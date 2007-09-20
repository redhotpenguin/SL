package SL::Apache::App::Router;

use strict;
use warnings;

use Apache2::Const -compile => qw(OK SERVER_ERROR NOT_FOUND M_GET M_POST);
use Apache2::Log        ();
use Apache2::SubRequest ();
use Data::FormValidator ();
use Apache2::Request    ();
use Apache2::SubRequest ();

use base 'SL::Apache::App';

use SL::App::Template ();
our $tmpl = SL::App::Template->template();

# this specific template logic
use Data::Dumper;
use SL::Model;
use SL::Model::App;    # works for now

sub dispatch_index {
    my ($self, $r) = @_;

    my %tmpl_data = ( root => $r->pnotes('root'),
                       email => $r->user);
    my $output;
    my $ok = $tmpl->process('router/index.tmpl', \%tmpl_data, \$output);
    $ok ? return $self->ok($r, $output) 
        : return $self->error($r, "Template error: " . $tmpl->error());
}


sub dispatch_edit {
    my ( $self, $r, $args_ref ) = @_;

    my $req = $args_ref->{req} || Apache2::Request->new($r);

    my $reg = $r->pnotes($r->user);
    my ( @locations, @reg__ad_groups, $router, $output, $link );
    if ( $req->param('router_id') ) {    # edit existing router

      my ($router__reg) =
        SL::Model::App->resultset('RouterReg')->search({
                   reg_id    => $reg->reg_id,
                   router_id => $req->param('router_id'), });

      unless ($router__reg) {
          $r->log->error(sprintf("unauthorized access, router %s, reg %s",
                               $req->param('router_id'), $reg->reg_id ));
          return Apache2::Const::NOT_FOUND;
      }
      $router = $router__reg->router_id;

      # get the locations for the router
      @locations = map { $_->location_id } $router->router__locations;
   }

    # ugh this code sucks, but it basically populates which ad groups are
    # selected for the router, and also handles the case of adding new
    # ad groups to routers
    my @router__ad_groups;
    if ($router) {
      # current associations for this router
      @router__ad_groups = map { $_->ad_group_id } $router->router__ad_groups;
    }
      # ad groups allowed for this user
    @reg__ad_groups = map { $_->ad_group_id } $reg->reg__ad_groups;

    if ($router) {
      # mark the already associated ad groups as selected
      foreach my $reg__ad_group ( @reg__ad_groups ) {
        if ( grep { $reg__ad_group->ad_group_id eq $_ } @router__ad_groups ) {
          $reg__ad_group->{selected} = 1;
        }
      }
    }

    if ( $r->method_number == Apache2::Const::M_GET ) {
        my %tmpl_data = (
            root     => $r->pnotes('root'),
            reg      => $reg,
            ad_groups => \@reg__ad_groups,
            router   => $router,
            locations => scalar(@locations > 0) ? \@locations :  '',
            errors   => $args_ref->{errors},
            req      => $req,
        );

        my $ok = $tmpl->process( 'router/edit.tmpl', \%tmpl_data, \$output );
        $ok
          ? return $self->ok( $r, $output )
          : return $self->error( $r, "Template error: " . $tmpl->error() );
    }
    elsif ( $r->method_number == Apache2::Const::M_POST ) {

        # reset method to get for redirect
        $r->method_number(Apache2::Const::M_GET);
        my %router_profile = (
            required           => [qw( name macaddr )],
            constraint_methods => { macaddr => valid_macaddr() }
        );
        my $results = Data::FormValidator->check( $req, \%router_profile );

        # handle form errors
        if ( $results->has_missing or $results->has_invalid ) {
          my $errors = $self->SUPER::_results_to_errors($results);
            return $self->dispatch_edit($r,{
                    errors => $errors,
                    req    => $req
                });
        }
      }


    if ( not defined $router ) {
        # this logic in here is a bit sticky, since someone else could have
        # registered this router, but this user wants to use it also
        # see if there is a router we don't know about that someone else added
        ($router) =
          SL::Model::App->resultset('Router')
          ->search( { macaddr => $req->param('macaddr') } );
        unless ($router) {

            # adding a new router
            $router =
              SL::Model::App->resultset('Router')->new( { active => 't' } );
            $router->insert;
            $router->update;
          }

        # see if a router reg exists
        my %reg_args = (
            reg_id    => $r->pnotes( $r->user )->reg_id,
            router_id => $router->router_id,
        );
        my ($router__reg) =
          SL::Model::App->resultset('RouterReg')->search( \%reg_args );

        unless ($router__reg) {

            # nothing so make a new one
            $router__reg =
              SL::Model::App->resultset('RouterReg')->new( \%reg_args );
          }
        $router__reg->insert;
        $router__reg->update;
      }

    # no errors update the router
    my $feed_google = ($req->param('feed_google') == 1) ? 1 : 0;
    my $feed_linkshare = ($req->param('feed_linkshare') == 1) ? 1 : 0;
    $router->feed_google($feed_google);
    $router->feed_linkshare($feed_linkshare);
    foreach my $param qw( name macaddr serial_number ) {
        $router->$param( $req->param($param) );
      }
    $router->update;

    # and update the associated ad groups for this router
    # first get rid of the old associations
    SL::Model::App->resultset('RouterAdGroup')->search(
          {router_id => $router->router_id })->delete_all;

    foreach my $ad_group_id ( $req->param('ad_group') ) {
      SL::Model::App->resultset('RouterAdGroup')->find_or_create({
          router_id => $router->router_id,
          ad_group_id => $ad_group_id, });
    }

    my $status = $req->param('router_id') ? 'updated' : 'created';
    $r->pnotes('session')->{msg} = sprintf("Router '%s' was %s",
                                             $router->name, $status);
    $r->internal_redirect("/app/router/list");
    return Apache2::Const::OK;
}

sub dispatch_list {
    my ( $self, $r, $args_ref ) = @_;

    my $reg = $r->pnotes($r->user);
    my $req = Apache2::Request->new($r);

    my @routers = $reg->get_routers( $req->param('ad_group_id') );

    my %tmpl_data = (
        root  => $r->pnotes('root'),
        session => $r->pnotes('session'),
        routers => \@routers,
        count => scalar(@routers),
    );

    my $output;
    my $ok = $tmpl->process( 'router/list.tmpl', \%tmpl_data, \$output );
    $ok
      ? return $self->ok( $r, $output )
      : return $self->error( $r, "Template error: " . $tmpl->error() );
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
