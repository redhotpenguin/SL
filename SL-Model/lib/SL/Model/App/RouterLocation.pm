package SL::Model::App::RouterLocation;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("InflateColumn::DateTime", "Core");
__PACKAGE__->table("router__location");
__PACKAGE__->add_columns(
  "router_id",
  {
    data_type => "integer",
    default_value => undef,
    is_foreign_key => 1,
    is_nullable => 0,
    size => 4,
  },
  "location_id",
  {
    data_type => "integer",
    default_value => undef,
    is_foreign_key => 1,
    is_nullable => 0,
    size => 4,
  },
  "mts",
  {
    data_type => "timestamp with time zone",
    default_value => "now()",
    is_nullable => 1,
    size => 8,
  },
);
__PACKAGE__->set_primary_key("router_id", "location_id");
__PACKAGE__->belongs_to(
  "location",
  "SL::Model::App::Location",
  { location_id => "location_id" },
);
__PACKAGE__->belongs_to(
  "router",
  "SL::Model::App::Router",
  { router_id => "router_id" },
);


# Created by DBIx::Class::Schema::Loader v0.04999_07 @ 2009-06-14 16:15:26
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:qtAPJI8b84NZLV+AbF0PrA


# You can replace this text with custom content, and it will be preserved on regeneration
1;
