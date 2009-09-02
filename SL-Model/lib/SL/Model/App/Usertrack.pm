package SL::Model::App::Usertrack;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("Core");
__PACKAGE__->table("usertrack");
__PACKAGE__->add_columns(
  "usertrack_id",
  {
    data_type => "integer",
    default_value => "nextval('usertrack_usertrack_id_seq'::regclass)",
    is_auto_increment => 1,
    is_nullable => 0,
    size => 4,
  },
  "router_id",
  {
    data_type => "integer",
    default_value => 1,
    is_foreign_key => 1,
    is_nullable => 0,
    size => 4,
  },
  "totalkb",
  { data_type => "integer", default_value => 0, is_nullable => 0, size => 4 },
  "hostname",
  {
    data_type => "text",
    default_value => "''::text",
    is_nullable => 0,
    size => undef,
  },
  "kbup",
  { data_type => "integer", default_value => 0, is_nullable => 0, size => 4 },
  "kbdown",
  { data_type => "integer", default_value => 0, is_nullable => 0, size => 4 },
  "mac",
  { data_type => "macaddr", default_value => undef, is_nullable => 1, size => 6 },
  "cts",
  {
    data_type => "timestamp without time zone",
    default_value => "now()",
    is_nullable => 1,
    size => 8,
  },
);
__PACKAGE__->set_primary_key("usertrack_id");
__PACKAGE__->belongs_to(
  "router",
  "SL::Model::App::Router",
  { router_id => "router_id" },
);


# Created by DBIx::Class::Schema::Loader v0.04999_08 @ 2009-09-01 15:52:24
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:eGlL0nR4DpbUUMBIeqatVg


# You can replace this text with custom content, and it will be preserved on regeneration
1;
