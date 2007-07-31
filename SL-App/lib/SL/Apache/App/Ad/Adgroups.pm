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
    my $output;
    my $ok = $tmpl->process( 'ad/adgroups/index.tmpl', \%tmpl_data, \$output );
    $ok
      ? return $self->ok( $r, $output )
      : return $self->error( $r, "Template error: " . $tmpl->error() );
}

sub dispatch_list {
  my ($self, $r, $args_ref) = @_;

  # get all ads for this user
  my @ads = SL::Model::App->resultset('AdSl')->search({
                                  reg_id => $r->pnotes($r->user)->reg_id, },);
  my @ad_ids = map { $_->ad_id->ad_id } @ads;

  # get the ad_group_ids for this user
  my @ad_groups = SL::Model::App->resultset('AdGroup')->search({
    reg_id => $r->pnotes($r->user)->reg_id, },);
  my @ad_group_ids = map { $_->ad_group_id } @ad_groups;

  # now grab the ad__ad_groups
  my @ad__ad_groups = SL::Model::App->resultset('AdAdGroup')->search({
               ad_id => { -in => \@ad_ids },
               ad_group_id => { -in => \@ad_group_ids }, });

  my %ad_hash = map { $_->ad_id->ad_id => $_->text } @ads;

  foreach my $ad__ad_group (@ad__ad_groups) {
    $ad__ad_group->{ad_text} = $ad_hash{$ad__ad_group->ad_id->ad_id};
  }

    my %tmpl_data = (
        root  => $r->pnotes('root'),
        session => $r->pnotes('session'),
        ads => \@ads,
        ad_groups => \@ad_groups,
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
