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

sub dispatch_edit {
    my ( $self, $r, $args_ref ) = @_;

    my $req = $args_ref->{req} || Apache2::Request->new($r);
    my $reg = $r->pnotes( $r->user );

    # get the list of friends
    my @friends = $reg->friends;
    my ( $ad_group, $output);

    if ( my $ad_group_id = $req->param('id') ) {

        # edit existing ad group

        $ad_group = $reg->get_ad_group($ad_group_id);
        return Apache2::Const::NOT_FOUND unless $ad_group;

        # i can has ad_group
        foreach my $friend (@friends) {
          my ($has_adgroup) = SL::Model::App->resultset('RegAdGroup')->search({
                       ad_group_id => $ad_group_id,
                       reg_id => $friend->reg_id });
          $friend->{selected} = 1 if $has_adgroup;
        }
    }

    # get the bugs which this user owns, plus default bugs
    my @bugs = SL::Model::App->resultset('Bug')->search(
        [
            { reg_id => $r->pnotes( $r->user )->reg_id, }, { is_default => 't' }
        ]
    );

    if ( $r->method_number == Apache2::Const::M_GET ) {
        my %tmpl_data = (
            root     => $r->pnotes('root'),
            reg      => $r->pnotes( $r->user ),
            bugs     => \@bugs,
            friends  => \@friends,
            ad_group => $ad_group,
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

        # validate input
        my %ad_group_profile = (
            required           => [qw( name  bug_id active )],
        );

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

    unless ( $req->param('id') ) {

        # create a new ad group
        $ad_group =
          SL::Model::App->resultset('AdGroup')->create( {
                is_default => 'f', reg_id => $reg->reg_id } );
    }

    # add arguments
    foreach my $param qw( name bug_id active ) {
        $ad_group->$param( $req->param($param) );
    }
    $r->log->debug("ISA: " . join(',', @SL::Model::App::AdGroup::ISA));

    $ad_group->update;

    my $reg__ad_group =
      SL::Model::App->resultset('RegAdGroup')->update_or_create(
        {
            reg_id      => $r->pnotes( $r->user )->reg_id,
            ad_group_id => $ad_group->ad_group_id
        }
      );


    # add the permissions for this ad
    if ( $ad_group->reg_id->reg_id == $reg->reg_id )
    {
        my %update_friends = map { $_ => 1 } $req->param('friends');
        foreach my $friend (@friends) {
            my %search = (
                ad_group_id => $ad_group->ad_group_id,
                reg_id      => $friend->reg_id
            );

            if ( exists $update_friends{ $friend->reg_id } ) {

                # give access
                my $rs = SL::Model::App->resultset('RegAdGroup')
                  ->find_or_create( \%search );

            }
            else {
                SL::Model::App->resultset('RegAdGroup')->search( \%search )
                  ->delete;
            }
        }
    }

    # done with argument processing
   my $status = $req->param('id') ? 'updated' : 'created';
    $r->pnotes('session')->{msg} =
      sprintf( "Ad group '%s' was %s", $ad_group->name, $status );
    $r->internal_redirect("/app/ad/groups/list");
    return Apache2::Const::OK;
}

sub dispatch_list {
    my ( $self, $r, $args_ref ) = @_;

    my $reg = $r->pnotes( $r->user );

    # get the ad groups this user has access to
    my @ad_groups = $reg->get_ad_groups;

    foreach my $ad_group (@ad_groups) {

        # Hack
        if ( $ad_group->template eq 'text_ad.tmpl' ) {
            $ad_group->{type} = 'Static Text';
        }
        else {
            $ad_group->{type} = 'Other';
        }
    }

    my %tmpl_data = (
        root      => $r->pnotes('root'),
        session   => $r->pnotes('session'),
        ad_groups => \@ad_groups,
        count     => scalar(@ad_groups),
    );

    my $output;
    my $ok = $tmpl->process( 'ad/groups/list.tmpl', \%tmpl_data, \$output );
    $ok
      ? return $self->ok( $r, $output )
      : return $self->error( $r, "Template error: " . $tmpl->error() );
}

1;
