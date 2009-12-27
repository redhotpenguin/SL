package SL::App::Ad::Groups;

use strict;
use warnings;

use Apache2::Const -compile =>
  qw(OK SERVER_ERROR NOT_FOUND REDIRECT M_GET M_POST HTTP_METHOD_NOT_ALLOWED );
use Apache2::Log        ();
use Apache2::SubRequest ();
use Data::FormValidator ();
use Apache2::Request    ();
use Apache2::SubRequest ();

# be careful, this was breaking things
#use JavaScript::Minifier::XS qw(minify);

use base 'SL::App';

use SL::Config        ();
use SL::Model         ();
use SL::Model::App    ();
use SL::App::Template ();
use Data::Dumper;

our $Config = SL::Config->new;

our $Tmpl = SL::App::Template->template();

use constant DEBUG => $ENV{SL_DEBUG} || 0;

sub dispatch_index {
    my ( $self, $r ) = @_;

    my $output;
    $Tmpl->process( 'ad/groups/index.tmpl', {}, \$output, $r )
      || return $self->error( $r, $Tmpl->error );

    return $self->ok( $r, $output );
}

sub dispatch_add {
    my ( $self, $r ) = @_;

    my $req = Apache2::Request->new($r);
    my $reg = $r->pnotes( $r->user );

    if ( $r->method_number == Apache2::Const::M_GET ) {

        my $ad_zone = SL::Model::App->resultset('AdZone')->create(
            {
                name       => 'New Banner Ad',
                account_id => $reg->account_id,
                reg_id     => $reg->reg_id,
                ad_size_id => 12, # Floating Footer Leaderboard
                code       => '',
                active     => 1,
                is_default => 0,
                image_href => 'http://s1.slwifi.com/images/ads/sln/sl_leaderboard.gif',
                link_href => 'http://www.silverliningnetworks.com/?referer=newad',
            }
        );
        return Apache2::Const::NOT_FOUND unless $ad_zone;
        $ad_zone->update;


        return $self->dispatch_edit( $r, { req => $req }, $ad_zone );

    }

}

sub dispatch_assign {
    my ( $self, $r ) = @_;

    my $req = Apache2::Request->new($r);
    my $reg = $r->pnotes( $r->user );

    if ( $r->method_number == Apache2::Const::M_GET ) {

        my $ad_zone = $reg->get_ad_zone( $req->param('id') );
        return Apache2::Const::NOT_FOUND unless $ad_zone;

        my @routers = $reg->get_routers;

        foreach my $router (@routers) {

            my $assign =
              SL::Model::App->resultset('RouterAdZone')->find_or_create(
                {
                    router_id  => $router->router_id,
                    ad_zone_id => $ad_zone->ad_zone_id,
                }
              );
            $assign->update;
        }

        $r->pnotes('session')->{msg} =
          sprintf( "Ad Zone '%s' was assigned to all routers", $ad_zone->name );

        $r->headers_out->set(
            Location => $r->construct_url('/app/ad/groups/list') );
        return Apache2::Const::REDIRECT;

    }
    else {

        return Apache2::Const::HTTP_METHOD_NOT_ALLOWED;
    }

}

sub dispatch_remove {
    my ( $self, $r ) = @_;

    my $req = Apache2::Request->new($r);
    my $reg = $r->pnotes( $r->user );

    if ( $r->method_number == Apache2::Const::M_GET ) {

        my $ad_zone = $reg->get_ad_zone( $req->param('id') );
        return Apache2::Const::NOT_FOUND unless $ad_zone;

        my @routers = $reg->get_routers;

        foreach my $router (@routers) {

            my @razs = grep {
                $_->ad_zone->ad_size->grouping == $ad_zone->ad_size->grouping
            } $router->router__ad_zones;

            $_->delete for @razs;
        }

        $r->pnotes('session')->{msg} =
          sprintf( "Ad Zone '%s' was removed from all routers",
            $ad_zone->name );

        $r->headers_out->set(
            Location => $r->construct_url('/app/ad/groups/list') );
        return Apache2::Const::REDIRECT;

    }
    else {

        return Apache2::Const::HTTP_METHOD_NOT_ALLOWED;
    }

}

sub dispatch_edit {
    my ( $self, $r, $args_ref, $ad_zone_obj ) = @_;

    my $req = $args_ref->{req} || Apache2::Request->new($r);
    my $reg = $r->pnotes( $r->user );

    my $ad_zone;
    if (my $id = $req->param('id')) {

      $ad_zone = $reg->get_ad_zone( $id );

    } elsif ($ad_zone_obj) {

      $ad_zone = $ad_zone_obj;

    }

    return Apache2::Const::NOT_FOUND unless $ad_zone;

    if ( $r->method_number == Apache2::Const::M_GET ) {

        my %tmpl_data = (
            image_err => $args_ref->{image_err},
            ad_zone  => $ad_zone,
            results => $args_ref->{results},
            errors   => $args_ref->{errors},
            req      => $req,
        );

        my $output;
        $Tmpl->process( 'ad/groups/edit.tmpl', \%tmpl_data, \$output, $r )
          || return $self->error( $r, $Tmpl->error );
        return $self->ok( $r, $output );
    }
    elsif ( $r->method_number == Apache2::Const::M_POST ) {

        # reset the method
        $r->method_number(Apache2::Const::M_GET);

        # validate input
        my @required = qw( name zone_type active is_default id banner_placement display_rate );
        my @optionals = qw( floating );
        my $constraints;
        if ( $req->param('zone_type') eq 'banner' ) {

            push @required, qw( image_href link_href );
            $constraints = {
                image_href => $self->valid_banner_ad(),
                link_href  => $self->valid_link(),
            };

            push @optionals, ( qw( code ) );

        }
        elsif ( $req->param( 'zone_type' eq 'code' ) ) {

            push @required, 'code';
            push @optionals, ( qw( image_href link_href ) );
        }

        my %profile = ( required => \@required, optional => \@optionals );
        if ($constraints) {
            $profile{constraint_methods} = $constraints;
        }

        my $results = Data::FormValidator->check( $req, \%profile );

        if ( $results->has_missing or $results->has_invalid ) {
            my $errors = $self->SUPER::_results_to_errors($results);

            $r->log->debug( Dumper($results) ) if DEBUG;

            return $self->dispatch_edit(
                $r,
                {
                    results => $results,
                    image_err => $results->{image_err},
                    errors => $errors,
                    req    => $req
                }
            );
        }
    }

    # calculate the ad size
    my $ad_size_id;
    if ($req->param('banner_placement') eq 'bottom') {

       # must be floating footer leaderboard, no static footer
       $ad_size_id = 12;

     } elsif ($req->param('banner_placement') eq 'top') {

       if ($req->param('floating')) {

         # floating top leaderboard
         $ad_size_id = 10;

       } else {

         # static leaderboard
         $ad_size_id = 1;
       }
    }


    # calculate the weight
    my $weight = $self->display_weight( $req->param('display_rate') );


    # remove this line and suffer the consequences
    my $code = $req->param('code');

    # fredify the invocation code for size
    #$code =~ s/(?:\t|\r|\n|\s{2,})/ /g;
    # $code = minify( $code );
    my %args = (
        weight     => $weight,
        reg_id     => $reg->reg_id,
        account_id => $reg->account->account_id,
        ad_size_id => $ad_size_id,
        name       => $req->param('name'),
        active     => $req->param('active'),
    );

    if ( $req->param('zone_type') eq 'code' ) {

        # use the invocation code
        $args{'code'}       = $req->param('code');
        $args{'image_href'} = '';
        $args{'link_href'}  = '';

    }
    elsif ( $req->param('zone_type') eq 'banner' ) {

        # create a simple link
        $args{'image_href'} = $req->param('image_href');
        $args{'link_href'}  = $req->param('link_href');
        String::Strip::StripLTSpace($args{'link_href'});
        String::Strip::StripLTSpace($args{'image_href'});
        $args{'code'}       = sprintf( '<a href="%s"><img border="0" src="%s"></a>',
            $args{'link_href'}, $args{'image_href'} );
    }

    # add arguments
    $ad_zone->$_( $args{$_} ) for keys %args;
    $ad_zone->mts( DateTime::Format::Pg->format_datetime( DateTime->now( time_zone => 'local')));


    ############################################
    # handle default
    my @default_zones = SL::Model::App->resultset('AdZone')->search({
	            account_id => $reg->account_id,
                     ad_size_id => { -in => [ qw( 1 10 12 ) ] },
                    is_default => 1 });

    if ($req->param('is_default') == 1) {

      # null out the existing default zones
      foreach my $dz ( @default_zones ) {

        next if $dz->ad_zone_id == $ad_zone->ad_zone_id;

        $dz->is_default(0);
        $dz->update;
      }

      $ad_zone->is_default(1);

    } elsif ($req->param('is_default') == 0) {

      # mark this one as default UNLESS there are no existing defaults

      if (@default_zones && ($default_zones[0]->ad_zone_id != $ad_zone->ad_zone_id)) {
        $ad_zone->is_default(0);

      } else {

        $ad_zone->is_default(1);
      }

    }

    $ad_zone->update;

    $r->log->debug("updated ad zone: " . Data::Dumper::Dumper($ad_zone)) if DEBUG;

    # done with argument processing
    $r->pnotes('session')->{msg} = sprintf( "Ad Zone '%s' was updated", $ad_zone->name );

    $r->headers_out->set(
        Location => $r->construct_url('/app/ad/groups/list') );
    return Apache2::Const::REDIRECT;
}

sub dispatch_list {
    my ( $self, $r, $args_ref ) = @_;

    my $reg = $r->pnotes( $r->user );

    # get the ad zones this user has access to
    my @ad_zones =
      sort { $b->{router_count} <=> $a->{router_count} }
      sort { $b->mts cmp $a->mts }
      sort { $a->name cmp $b->name } $reg->get_persistent_zones;

    #$r->log->debug( "ad zones: " . Dumper( \@ad_zones ) ) if DEBUG;

    $self->format_adzone_list(\@ad_zones);

    my %tmpl_data = (
        ad_zones => \@ad_zones,
        count    => scalar(@ad_zones),
    );

    my $output;
    $Tmpl->process( 'ad/groups/list.tmpl', \%tmpl_data, \$output, $r )
      || return $self->error( $r, $Tmpl->error );
    return $self->ok( $r, $output );
}

1;
