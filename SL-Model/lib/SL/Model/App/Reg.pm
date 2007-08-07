package SL::Model::App::Reg;

use strict;
use warnings;

use base 'SL::Model::App';

sub friends {
    my $self = shift;

    my @friends = SL::Model::App->resultset('RegReg')->search(
        [
            { first_reg_id => $self->reg_id, }, { sec_reg_id => $self->reg_id, }
        ]
    );
    return unless ( scalar(@friends) > 0 );

    my @first = grep { $_->reg_id != $self->reg_id }
      map { $_->first_reg_id } @friends;
    my @sec = grep { $_->reg_id != $self->reg_id }
      map { $_->sec_reg_id } @friends;
    @friends = ( @first, @sec );
    return @friends;
}

sub get_ad_sl {
    my ( $self, $ad_sl_id ) = @_;

    my ($ad_sl) =
      SL::Model::App->resultset('AdSl')->search( { ad_sl_id => $ad_sl_id } );
    return unless $ad_sl;

    my ($has_perm) = SL::Model::App->resultset('RegAdGroup')->search(
        {
            reg_id      => $self->reg_id,
            ad_group_id => $ad_sl->ad_id->ad_group_id->ad_group_id,
        }
    );

    return unless $has_perm;
    return $ad_sl;
}

sub get_ad_group {
    my ( $self, $ad_group_id ) = @_;

    # check permissions
    my ($has_perm) =
      SL::Model::App->resultset('RegAdGroup')
      ->search( { reg_id => $self->reg_id, ad_group_id => $ad_group_id } );
    return unless $has_perm;

    my ($ad_group) =
      SL::Model::App->resultset('AdGroup')
      ->search( { ad_group_id => $ad_group_id } );

    return unless $ad_group;
    $self->process_ad_group($ad_group);

    return $ad_group;
}

sub get_ad_groups {
    my $self = shift;

    # ad groups allowed for this user
    my @ad_groups = map { $_->ad_group_id } $self->reg__ad_groups;

    return unless ( scalar(@ad_groups) > 0 );
    foreach my $ad_group (@ad_groups) {

        # get ad count
        $self->process_ad_group($ad_group);
    }

    return @ad_groups;
}

sub process_ad_group {
    my ( $self, $ad_group ) = @_;

    $ad_group->{ad_count} =
      SL::Model::App->resultset('Ad')
      ->search( { ad_group_id => $ad_group->ad_group_id } )->count;

    # get routers for this reg
    my @router_ids = map { $_->router_id } $self->routers;
    if ( scalar(@router_ids) == 0 ) {
        $ad_group->{router_count} = 0;
        next;
    }

    $ad_group->{router_count} =
      SL::Model::App->resultset('RouterAdGroup')->search(
        {
            ad_group_id => $ad_group->ad_group_id,
            router_id   => { -in => \@router_ids }
        }
      );

    # Hack
    if ( $ad_group->template eq 'text_ad.tmpl' ) {
        $ad_group->{type} = 'Static Text';
    }
    else {
        $ad_group->{type} = 'Other';
    }
    return 1;
}

sub routers {
    my ( $self, $args_ref ) = @_;

    my @routers = map { $_->router_id } $self->router__regs;

    return unless scalar(@routers) > 0;
    return @routers;
}

1;
