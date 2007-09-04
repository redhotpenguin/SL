package SL::Apache::App::Ad::Groups::Ads;

use strict;
use warnings;

use Apache2::Const -compile => qw(OK SERVER_ERROR NOT_FOUND M_GET M_POST);
use Apache2::Log        ();
use Apache2::SubRequest ();
use Data::FormValidator ();
use Apache2::Request    ();
use Apache2::SubRequest ();

use base 'SL::Apache::App';

use SL::Config;
our $CONFIG = SL::Config->new;

use SL::App::Template ();
our $tmpl = SL::App::Template->template();

# this specific template logic
use Data::Dumper;
use SL::Model;
use SL::Model::App;    # works for now

sub shrink {
    my $string = shift;
    my $length = 50;
    return $string if ( length($string) - 3 ) < $length;
    return substr( $string, -length($string), $length ) . '...';
}

sub dispatch_list {
    my ( $self, $r ) = @_;

    my $reg = $r->pnotes( $r->user );
    my $req = Apache2::Request->new($r);
    my $ad_group_id = $req->param('ad_group_id');

    my $ad_group = $reg->get_ad_group($ad_group_id);
    return Apache2::Const::NOT_FOUND unless $ad_group;

    my @ad_sls = $ad_group->get_ad_sls;

    foreach my $ad_sl (@ad_sls) {
      $ad_sl->text( shrink($ad_sl->text) );
    }

    my %tmpl_data = (
        root     => $r->pnotes('root'),
        session  => $r->pnotes('session'),
        ad_sls   => \@ad_sls,
        ad_group => $ad_group,
    );

    my $output;
    my $ok = $tmpl->process( 'ad/groups/ads/list.tmpl', \%tmpl_data, \$output );
    $ok
      ? return $self->ok( $r, $output )
      : return $self->error( $r, "Template error: " . $tmpl->error() );
}

sub dispatch_edit {
    my ( $self, $r, $args_ref ) = @_;

    my $req = $args_ref->{req} || Apache2::Request->new($r);
    my $reg = $r->pnotes($r->user);

    my ( %tmpl_data, $ad_sl, $output, $link, $ad_group, @friends );
    if ( $req->param('ad_sl_id') ) {    # edit existing ad

        $ad_sl = $reg->get_ad_sl( $req->param('ad_sl_id') );
        return Apache2::Const::NOT_FOUND unless $ad_sl;

        # fetch the ad group
        $ad_group = $ad_sl->ad_id->ad_group_id;
    } else {
      $ad_group = $reg->get_ad_group($req->param('ad_group_id'));
      return Apache2::Const::NOT_FOUND unless $ad_group;
    }

    if ( $r->method_number == Apache2::Const::M_GET ) {
        %tmpl_data = (
            ad_sl => $ad_sl,
            reg => $reg,
            ad_group => $ad_group,
            session => $r->pnotes('session'),
            root    => $r->pnotes('root'),
            req     => $req,
            errors => $args_ref->{errors},
        );
        my $ok = $tmpl->process( 'ad/groups/ads/edit.tmpl',
                                 \%tmpl_data, \$output );
        $ok
          ? return $self->ok( $r, $output )
          : return $self->error( $r, "Template error: " . $tmpl->error() );
    }
    elsif ( $r->method_number == Apache2::Const::M_POST ) {

        $r->method_number(Apache2::Const::M_GET);
        my %ad_profile = ( required => [qw( uri text active )], );
        my $results = Data::FormValidator->check( $req, \%ad_profile );

        if ($results->has_missing or $results->has_invalid) {
          my $errors = $self->SUPER::_results_to_errors($results);
          return $self->dispatch_edit( $r, { errors => $errors, req => $req } );
        }
    }

    my ($base_ad, $action);
    unless ($ad_sl ) {

        # make the base ad first
        $base_ad = SL::Model::App->resultset('Ad')->new( { active => 't', ad_group_id => $req->param('ad_group_id')  } );
        $base_ad->insert();

        # make the sl_ad
        $ad_sl = SL::Model::App->resultset('AdSl')->new(
            {
                ad_id  => $base_ad->ad_id,
                text   => $req->param('text'),
                uri    => $req->param('uri'),
                reg_id => $reg->reg_id,
            }
        );
        $ad_sl->insert();
        $base_ad->update;
        $ad_sl->update;
        $action = 'added';
    }
    else {
      # update the existing ad
        $ad_sl->ad_id->active( $req->param('active') );
        foreach my $param qw( text uri ) {
          $ad_sl->$param( $req->param($param) );
        }
        $ad_sl->ad_id->update;
        $ad_sl->update;
        $action = 'updated';
    }

    # set session msg
    $r->pnotes('session')->{msg} =
      sprintf( "Ad '%s' has been %s", $req->param('text'), $action );

    # set session msg
    $r->internal_redirect(  "/app/ad/groups/ads/list?ad_group_id=" . $ad_group->ad_group_id );
    return Apache2::Const::OK;
}

1;
