package SL::Model::App::View;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("InflateColumn::DateTime", "Core");
__PACKAGE__->table("view");
__PACKAGE__->add_columns(
  "view_id",
  {
    data_type => "integer",
    default_value => "nextval('view_view_id_seq'::regclass)",
    is_auto_increment => 1,
    is_nullable => 0,
    size => 4,
  },
  "ad_zone_id",
  {
    data_type => "integer",
    default_value => undef,
    is_foreign_key => 1,
    is_nullable => 0,
    size => 4,
  },
  "cts",
  {
    data_type => "timestamp without time zone",
    default_value => "now()",
    is_nullable => 1,
    size => 8,
  },
  "ip",
  {
    data_type => "inet",
    default_value => undef,
    is_nullable => 1,
    size => undef,
  },
  "url",
  {
    data_type => "text",
    default_value => "''::text",
    is_nullable => 1,
    size => undef,
  },
  "referer",
  {
    data_type => "text",
    default_value => "''::text",
    is_nullable => 1,
    size => undef,
  },
  "usr_id",
  {
    data_type => "character varying",
    default_value => 1,
    is_nullable => 1,
    size => 8,
  },
  "router_id",
  {
    data_type => "integer",
    default_value => 1,
    is_foreign_key => 1,
    is_nullable => 1,
    size => 4,
  },
);
__PACKAGE__->set_primary_key("view_id");
__PACKAGE__->belongs_to(
  "router",
  "SL::Model::App::Router",
  { router_id => "router_id" },
  { join_type => "LEFT" },
);
__PACKAGE__->belongs_to(
  "ad_zone",
  "SL::Model::App::AdZone",
  { ad_zone_id => "ad_zone_id" },
);


# Created by DBIx::Class::Schema::Loader v0.04999_07 @ 2009-06-14 16:15:26
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:JRPq0UJ+JMNpcLxD0y2msA


# You can replace this text with custom content, and it will be preserved on regeneration
1;
