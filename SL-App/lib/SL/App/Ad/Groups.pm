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
                name       => 'New Ad Zone',
                account_id => $reg->account_id,
                reg_id     => $reg->reg_id,
                ad_size_id => 12,
                code       => '',
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

        my @ad_sizes = sort { $a->grouping <=> $b->grouping }
          sort { $a->name cmp $b->name } $reg->get_persistent_sizes;

        my %tmpl_data = (
            ad_sizes => \@ad_sizes,
            ad_zone  => $ad_zone,
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
        my @required = qw( name ad_size_id zone_type );
        my $constraints;
        if ( $req->param('zone_type') eq 'banner' ) {

            push @required, qw( image_href link_href );
            $constraints = {
                image_href => $self->valid_link(),
                link_href  => $self->valid_link(),
            };

        }
        elsif ( $req->param( 'zone_type' eq 'code' ) ) {

            push @required, 'code';
        }

        my %profile = ( required => \@required, );
        if ($constraints) {
            $profile{constraint_methods} = $constraints;
        }

        my $results = Data::FormValidator->check( $req, \%profile );

        if ( $results->has_missing or $results->has_invalid ) {
            my $errors = $self->SUPER::_results_to_errors($results);

            $r->log->debug( Dumper($results) ) if DEBUG;
            $r->log->debug( Dumper($errors) ) if DEBUG;

            return $self->dispatch_edit(
                $r,
                {
                    errors => $errors,
                    req    => $req
                }
            );
        }
    }

    # remove this line and suffer the consequences
    my $code = $req->param('code');

    # fredify the invocation code for size
    #$code =~ s/(?:\t|\r|\n|\s{2,})/ /g;
    # $code = minify( $code );
    my %args = (
        reg_id     => $reg->reg_id,
        account_id => $reg->account->account_id,
        ad_size_id => $req->param('ad_size_id'),
        name       => $req->param('name'),
        active     => $req->param('active') || 'f',
        is_default => $req->param('is_default') || 'f',
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
        $args{'code'}       = sprintf( '<a href="%s"><img src="%s"></a>',
            $args{'link_href'}, $args{'image_href'} );
    }

    # add arguments
    $ad_zone->$_( $args{$_} ) for keys %args;
    $ad_zone->bug_id( 1 );
    $ad_zone->mts( DateTime::Format::Pg->format_datetime( DateTime->now( time_zone => 'local')));
    $ad_zone->update;

    $r->log->debug("ad zone is " . Dumper($ad_zone)) if DEBUG;


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

    $_->mts( $self->sldatetime( $_->mts ) ) for @ad_zones;

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
