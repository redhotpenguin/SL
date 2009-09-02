package SL::Model::App::Checkin;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("Core");
__PACKAGE__->table("checkin");
__PACKAGE__->add_columns(
  "checkin_id",
  {
    data_type => "integer",
    default_value => "nextval('checkin_checkin_id_seq'::regclass)",
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
  "memfree",
  { data_type => "integer", default_value => 0, is_nullable => 0, size => 4 },
  "users",
  { data_type => "integer", default_value => 0, is_nullable => 0, size => 4 },
  "kbup",
  { data_type => "integer", default_value => 0, is_nullable => 0, size => 4 },
  "kbdown",
  { data_type => "integer", default_value => 0, is_nullable => 0, size => 4 },
  "cts",
  {
    data_type => "timestamp without time zone",
    default_value => "now()",
    is_nullable => 1,
    size => 8,
  },
);
__PACKAGE__->set_primary_key("checkin_id");
__PACKAGE__->belongs_to(
  "router",
  "SL::Model::App::Router",
  { router_id => "router_id" },
);


# Created by DBIx::Class::Schema::Loader v0.04999_08 @ 2009-09-01 13:55:06
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:TY3SkhVpWOcT8BTDfiSKiw


# You can replace this text with custom content, and it will be preserved on regeneration
1;
