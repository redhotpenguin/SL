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

    my ( $ad_group, $output, $link );
    if ( $req->param('id') ) {    # edit existing ad group
        my ($reg__ad_group) = SL::Model::App->resultset('RegAdGroup')->search({
                                      reg_id => $r->pnotes($r->user)->reg_id,
                                      ad_group_id => $req->param('id')});
        $ad_group = $reg__ad_group->ad_group_id;
        return Apache2::Const::NOT_FOUND unless $ad_group;
    }

    # get the bugs which this user owns, plus default bugs
    my @bugs = SL::Model::App->resultset('Bug')->search([{
        reg_id => $r->pnotes($r->user)->reg_id, }, { is_default => 't' }]);

    if ( $r->method_number == Apache2::Const::M_GET ) {
        my %tmpl_data = (
            root     => $r->pnotes('root'),
            reg      => $r->pnotes( $r->user ),
            bugs     => \@bugs,
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
            constraint_methods => { css_url => SL::Apache::App::valid_link(), }
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

    unless ($req->param('id')) {
      # create a new ad group
      $ad_group = SL::Model::App->resultset('AdGroup')->create({ active => 't'});
    }
    # add arguments
    foreach my $param qw( name css_url bug_id active ) {
        $ad_group->$param( $req->param($param) );
    }
    $ad_group->update;

    my $reg__ad_group = SL::Model::App->resultset('RegAdGroup')->update_or_create({
             reg_id => $r->pnotes($r->user)->reg_id,
             ad_group_id => $ad_group->ad_group_id });

    my $status = $req->param('id') ? 'updated' : 'created';
    $r->pnotes('session')->{msg} = sprintf("Ad group '%s' was %s",
                                             $ad_group->name, $status);
    $r->internal_redirect("/app/ad/groups/list");
    return Apache2::Const::OK;
}

sub dispatch_list {
    my ( $self, $r, $args_ref ) = @_;

    my @reg__ad_groups = SL::Model::App->resultset('RegAdGroup')->search({
             reg_id => $r->pnotes($r->user)->reg_id });
    my @ad_groups      = map { $_->ad_group_id } @reg__ad_groups;
    # count up the ads in the group
    foreach my $group ( @ad_groups) {
      $group->{ad_count} = SL::Model::App->resultset('AdAdGroup')->search({
                          ad_group_id => $group->ad_group_id});
    }

    my %tmpl_data = (
        root  => $r->pnotes('root'),
        session => $r->pnotes('session'),
        ad_groups => \@ad_groups,
        count => scalar(@ad_groups),
    );

    my $output;
    my $ok = $tmpl->process( 'ad/groups/list.tmpl', \%tmpl_data, \$output );
    $ok
      ? return $self->ok( $r, $output )
      : return $self->error( $r, "Template error: " . $tmpl->error() );
}

1;
