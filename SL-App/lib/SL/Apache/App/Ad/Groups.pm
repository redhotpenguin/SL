package SL::Apache::App::Ad::Groups;

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

use DateTime;

sub shrink {
    my $string = shift;
    my $length = 25;
    return $string if ( length($string) - 3 ) < $length;
    return substr( $string, -length($string), $length ) . '...';
}

sub dispatch_index {
    my ( $self, $r ) = @_;

    my %tmpl_data = (
        root  => $r->pnotes('root'),
        email => $r->user
    );
    my $output;
    my $ok = $tmpl->process( 'ad/groups/index.tmpl', \%tmpl_data, \$output );
    $ok
      ? return $self->ok( $r, $output )
      : return $self->error( $r, "Template error: " . $tmpl->error() );
}

my %ad_group_profile =
  ( required => [qw( name bug_image_link bug_image_href )], );

sub dispatch_edit {
    my ( $self, $r, $args_ref ) = @_;

    my $req = $args_ref->{req} || Apache2::Request->new($r);

    my ( $ad_group, $bug, $output, $link );
    if ( $req->param('id') ) {    # edit existing ad group
        my %search;

        # restrict search params for nonroot
        if ( !$r->pnotes('root') ) {
            $search{reg_id} = $r->pnotes( $r->user )->reg_id;
        }

        $search{ad_group_id} = $req->param('id');
        ($ad_group) = SL::Model::App->resultset('AdGroup')->search( \%search );
        return Apache2::Const::NOT_FOUND unless $ad_group;
        $bug = $ad_group->bug_id;
    }

    if ( $r->method_number == Apache2::Const::M_GET ) {
        my %tmpl_data = (
            root     => $r->pnotes('root'),
            reg      => $r->pnotes( $r->user ),
            ad_group => $ad_group,
            bug      => $bug,
            errors   => $args_ref->{errors},
            status   => $args_ref->{status},
            req      => $req,
        );

        my $ok = $tmpl->process( 'ad/groups/edit.tmpl', \%tmpl_data, \$output );
        $ok
          ? return $self->ok( $r, $output )
          : return $self->error( $r, "Template error: " . $tmpl->error() );
    }
    elsif ( $r->method_number == Apache2::Const::M_POST ) {
        $r->method_number(Apache2::Const::M_GET);
        my $results = Data::FormValidator->check( $req, \%ad_group_profile );
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
    my $status;
    if ( not defined $ad_group ) {

        # make the ad_group
        $ad_group = SL::Model::App->resultset('AdGroup')->new( {} );
        $ad_group->insert();
        $status = 'added';
        $ad_group->update;
    }
    foreach my $param qw( name ) {
        $ad_group->$param( $req->param($param) );
    }
    $ad_group->update;

    return $self->dispatch_edit( $r, { status => 'update_ok' } );
}

1;
