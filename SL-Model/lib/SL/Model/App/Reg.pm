package SL::Model::App::Reg;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("Core");
__PACKAGE__->table("reg");
__PACKAGE__->add_columns(
  "reg_id",
  {
    data_type => "integer",
    default_value => "nextval('reg_reg_id_seq'::regclass)",
    is_nullable => 0,
    size => 4,
  },
  "email",
  {
    data_type => "character varying",
    default_value => "''::character varying",
    is_nullable => 0,
    size => 64,
  },
  "zipcode",
  {
    data_type => "character varying",
    default_value => "''::character varying",
    is_nullable => 1,
    size => 10,
  },
  "firstname",
  {
    data_type => "character varying",
    default_value => undef,
    is_nullable => 1,
    size => 32,
  },
  "lastname",
  {
    data_type => "character varying",
    default_value => undef,
    is_nullable => 1,
    size => 32,
  },
  "description",
  {
    data_type => "text",
    default_value => undef,
    is_nullable => 1,
    size => undef,
  },
  "street_addr",
  {
    data_type => "character varying",
    default_value => undef,
    is_nullable => 1,
    size => 64,
  },
  "apt_suite",
  {
    data_type => "character varying",
    default_value => undef,
    is_nullable => 1,
    size => 5,
  },
  "referer",
  {
    data_type => "character varying",
    default_value => undef,
    is_nullable => 1,
    size => 32,
  },
  "phone",
  {
    data_type => "character varying",
    default_value => undef,
    is_nullable => 1,
    size => 14,
  },
  "cts",
  {
    data_type => "timestamp without time zone",
    default_value => "now()",
    is_nullable => 1,
    size => 8,
  },
  "mts",
  {
    data_type => "timestamp without time zone",
    default_value => "now()",
    is_nullable => 1,
    size => 8,
  },
  "sponsor",
  {
    data_type => "character varying",
    default_value => undef,
    is_nullable => 1,
    size => 64,
  },
  "street_addr2",
  {
    data_type => "character varying",
    default_value => undef,
    is_nullable => 1,
    size => 64,
  },
  "city",
  {
    data_type => "character varying",
    default_value => undef,
    is_nullable => 1,
    size => 64,
  },
  "state",
  {
    data_type => "character",
    default_value => undef,
    is_nullable => 1,
    size => 2,
  },
  "active",
  {
    data_type => "boolean",
    default_value => "true",
    is_nullable => 1,
    size => 1,
  },
  "report_email",
  {
    data_type => "character varying",
    default_value => "''::character varying",
    is_nullable => 1,
    size => 64,
  },
  "password_md5",
  {
    data_type => "character varying",
    default_value => undef,
    is_nullable => 1,
    size => 32,
  },
  "send_reports_daily",
  {
    data_type => "boolean",
    default_value => "false",
    is_nullable => 1,
    size => 1,
  },
  "send_reports_weekly",
  {
    data_type => "boolean",
    default_value => "false",
    is_nullable => 1,
    size => 1,
  },
  "send_reports_monthly",
  {
    data_type => "boolean",
    default_value => "false",
    is_nullable => 1,
    size => 1,
  },
  "send_reports_quarterly",
  {
    data_type => "boolean",
    default_value => "false",
    is_nullable => 1,
    size => 1,
  },
  "report_email_frequency",
  {
    data_type => "character varying",
    default_value => "''::character varying",
    is_nullable => 0,
    size => 16,
  },
);
__PACKAGE__->set_primary_key("reg_id");
__PACKAGE__->has_many(
  "ad_groups",
  "SL::Model::App::AdGroup",
  { "foreign.reg_id" => "self.reg_id" },
);
__PACKAGE__->has_many(
  "ad_sls",
  "SL::Model::App::AdSl",
  { "foreign.reg_id" => "self.reg_id" },
);
__PACKAGE__->has_many(
  "bugs",
  "SL::Model::App::Bug",
  { "foreign.reg_id" => "self.reg_id" },
);
__PACKAGE__->has_many(
  "forgots",
  "SL::Model::App::Forgot",
  { "foreign.reg_id" => "self.reg_id" },
);
__PACKAGE__->has_many(
  "reg__ad_groups",
  "SL::Model::App::RegAdGroup",
  { "foreign.reg_id" => "self.reg_id" },
);
__PACKAGE__->has_many(
  "reg__reg_sec_reg_ids",
  "SL::Model::App::RegReg",
  { "foreign.sec_reg_id" => "self.reg_id" },
);
__PACKAGE__->has_many(
  "reg__reg_first_reg_ids",
  "SL::Model::App::RegReg",
  { "foreign.first_reg_id" => "self.reg_id" },
);
__PACKAGE__->has_many(
  "roots",
  "SL::Model::App::Root",
  { "foreign.reg_id" => "self.reg_id" },
);
__PACKAGE__->has_many(
  "router__regs",
  "SL::Model::App::RouterReg",
  { "foreign.reg_id" => "self.reg_id" },
);
__PACKAGE__->has_many(
  "urls",
  "SL::Model::App::Url",
  { "foreign.reg_id" => "self.reg_id" },
);

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
    my @router_ids = map { $_->router_id->router_id } $self->router__regs;
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
      )->count;

    # Hack
    if ( $ad_group->template eq 'text_ad.tmpl' ) {
        $ad_group->{type} = 'Static Text';
    }
    else {
        $ad_group->{type} = 'Other';
    }
    return 1;
}

sub process_router {
  my ($self, $router) = @_;

  $router->{location_count} = $router->router__locations->count;
  $router->{ad_group_count} = $router->router__ad_groups->count;

  return 1;
}

sub get_routers {
    my ( $self, $ad_group_id ) = @_;

    my @routers = map { $_->router_id } $self->router__regs;
    return unless (scalar(@routers) > 0);
    $self->process_router($_) for @routers;
    return @routers unless $ad_group_id;

    # filter the routers which have this ad group
    my @router_ids = map { $_->router_id } @routers;
    my @filtered_routers = map { $_->router_id }
        SL::Model::App->resultset('RouterAdGroup')->search(
                            { ad_group_id => $ad_group_id,
                              router_id => { -in => \@router_ids } });

    return unless (scalar(@filtered_routers) > 0);
    $self->process_router($_) for @routers;
    return @routers;
}

1;
