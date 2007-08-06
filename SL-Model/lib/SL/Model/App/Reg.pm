package SL::Model::App::Reg;

use strict;
use warnings;

use base 'SL::Model::App';


# returns ad_sl objects that this user has access to
sub ad_sls {
  my ($self, $args_ref) = @_;

  # what ads are we allowed access to?
  my @reg__ad_sls = map { $_->ad_sl_id  } $self->reg__ad_sls;
  my $rs = $self->SUPER::search({ %{$args_ref},
                                  ad_sl_id => { -in => \@reg__ad_sls }, });
  return $rs;
}

# returns ad_group objects this user has access to
sub ad_groups {
    my ($self, $args_ref) = @_;

    # what ad groups are we allowed access to?
    my @reg__ad_groups = map { $_->ad_group_id } $self->reg__ad_groups;
    my $rs = $self->SUPER::search({ %{$args_ref},
                                 ad_group_id => { -in => \@reg__ad_groups },});
    return $rs;
}

sub routers {
  my ($self, $args_ref) = @_;

  # hand back allowed routers
  my @router_ids = map { $_->router_id } $self->reg__routers;
  my $rs = $self->search({ %{$args_ref}, router_id => {-in => \@router_ids,}});
  return $rs;
}

1;
