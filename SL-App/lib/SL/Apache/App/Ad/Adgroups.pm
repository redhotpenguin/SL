package SL::Apache::App::Ad::Adgroups;

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

    # get the ad_groups for this user
    my @reg__ad_groups = SL::Model::App->resultset('RegAdGroup')->search({
                     reg_id => $r->pnotes($r->user)->reg_id });

    $tmpl_data{reg__ad_groups} = \@reg__ad_groups;
    # count up the ads in the group
    foreach my $reg__ad_group ( @reg__ad_groups) {
      $reg__ad_group->{ad_count} = 
        SL::Model::App->resultset('AdAdGroup')->search({
                          ad_group_id =>
                           $reg__ad_group->ad_group_id->ad_group_id});
    }

    my $output;
    my $ok = $tmpl->process( 'ad/adgroups/index.tmpl', \%tmpl_data, \$output );
    $ok
      ? return $self->ok( $r, $output )
      : return $self->error( $r, "Template error: " . $tmpl->error() );
}

sub dispatch_edit {
    my ( $self, $r, $args_ref ) = @_;

    my %tmpl_data = (
        root  => $r->pnotes('root'),
        email => $r->user
    );

  # get all ads for this user
  my @ads = SL::Model::App->resultset('AdSl')->search({
                                  reg_id => $r->pnotes($r->user)->reg_id, },);
  # get the ad_groups for this user
  my @ad_groups = SL::Model::App->resultset('AdGroup')->search({
    reg_id => $r->pnotes($r->user)->reg_id, },);

    $tmpl_data{ads} = \@ads;
    $tmpl_data{ad_groups} = \@ad_groups;

    my $output;
    my $ok = $tmpl->process( 'ad/adgroups/edit.tmpl', \%tmpl_data, \$output );
    $ok
      ? return $self->ok( $r, $output )
      : return $self->error( $r, "Template error: " . $tmpl->error() );
}

sub dispatch_list {
  my ($self, $r, $args_ref) = @_;

  my $req = $args_ref->{req} || Apache2::Request->new($r);

    my $ad_group_id = $req->param('ad_group_id');
    my ($reg__ad_group) = SL::Model::App->resultset('RegAdGroup')->search({
              ad_group_Id => $ad_group_id });
    return Apache2::Const::NOT_FOUND unless $reg__ad_group;

  # get all ads for this user
  my @ad_sls = SL::Model::App->resultset('AdSl')->search({
                                  reg_id => $r->pnotes($r->user)->reg_id, },);
  my @ad_ids = map { $_->ad_id->ad_id } @ad_sls;

  # now grab the ad__ad_groups
  my @ad__ad_groups = SL::Model::App->resultset('AdAdGroup')->search({
               ad_id => { -in => \@ad_ids },
               ad_group_id => $reg__ad_group->ad_group_id->ad_group_id });

  my %ad__ad_group_hash = map { $_->ad_id->ad_id => 1 } @ad__ad_groups;

   foreach my $ad_sl (@ad_sls) {
#      $ad_hash{$ad__ad_group->ad_id->ad_id}->{selected} = 1;
#      $ad__ad_group->{ad_text} = $ad_hash{$ad__ad_group->ad_id->ad_id};
  }

    my %tmpl_data = (
        root  => $r->pnotes('root'),
        session => $r->pnotes('session'),
        ads => \@ad_sls,
        ad_group => $reg__ad_group->ad_group_id,
        ad__ad_groups => \@ad__ad_groups,
        count => scalar(@ad__ad_groups),
    );

    my $output;
    my $ok = $tmpl->process( 'ad/adgroups/list.tmpl', \%tmpl_data, \$output );
    $ok
      ? return $self->ok( $r, $output )
      : return $self->error( $r, "Template error: " . $tmpl->error() );


}

1;
