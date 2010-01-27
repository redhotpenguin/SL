package SL::Model::App::AdZone;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("InflateColumn::DateTime", "Core");
__PACKAGE__->table("ad_zone");
__PACKAGE__->add_columns(
  "ad_zone_id",
  {
    data_type => "integer",
    default_value => "nextval('ad_zone_ad_zone_id_seq'::regclass)",
    is_auto_increment => 1,
    is_nullable => 0,
    size => 4,
  },
  "code",
  {
    data_type => "text",
    default_value => undef,
    is_nullable => 0,
    size => undef,
  },
  "name",
  {
    data_type => "text",
    default_value => undef,
    is_nullable => 0,
    size => undef,
  },
  "account_id",
  {
    data_type => "integer",
    default_value => undef,
    is_foreign_key => 1,
    is_nullable => 0,
    size => 4,
  },
  "ad_size_id",
  {
    data_type => "integer",
    default_value => undef,
    is_foreign_key => 1,
    is_nullable => 0,
    size => 4,
  },
  "active",
  {
    data_type => "boolean",
    default_value => "true",
    is_nullable => 0,
    size => 1,
  },
  "reg_id",
  {
    data_type => "integer",
    default_value => 1,
    is_foreign_key => 1,
    is_nullable => 0,
    size => 4,
  },
  "code_double",
  {
    data_type => "text",
    default_value => undef,
    is_nullable => 1,
    size => undef,
  },
  "public",
  {
    data_type => "boolean",
    default_value => "false",
    is_nullable => 0,
    size => 1,
  },
  "mts",
  {
    data_type => "timestamp without time zone",
    default_value => "now()",
    is_nullable => 1,
    size => 8,
  },
  "hidden",
  {
    data_type => "boolean",
    default_value => "false",
    is_nullable => 0,
    size => 1,
  },
  "is_default",
  {
    data_type => "boolean",
    default_value => "false",
    is_nullable => 0,
    size => 1,
  },
  "image_href",
  {
    data_type => "text",
    default_value => undef,
    is_nullable => 1,
    size => undef,
  },
  "link_href",
  {
    data_type => "text",
    default_value => undef,
    is_nullable => 1,
    size => undef,
  },
  "weight",
  {
    data_type => "integer",
    default_value => 1,
    is_foreign_key => 0,
    is_nullable => 0,
    size => 4,
  },
  "insertions_yesterday",
  {
    data_type => "integer",
    default_value => 0,
    is_foreign_key => 0,
    is_nullable => 0,
    size => 4,
  },
);
__PACKAGE__->set_primary_key("ad_zone_id");
__PACKAGE__->belongs_to("reg", "SL::Model::App::Reg", { reg_id => "reg_id" });
__PACKAGE__->belongs_to(
  "ad_size",
  "SL::Model::App::AdSize",
  { ad_size_id => "ad_size_id" },
);
__PACKAGE__->belongs_to(
  "account",
  "SL::Model::App::Account",
  { account_id => "account_id" },
);
__PACKAGE__->has_many(
  "router__ad_zones",
  "SL::Model::App::RouterAdZone",
  { "foreign.ad_zone_id" => "self.ad_zone_id" },
);
__PACKAGE__->has_many(
  "views",
  "SL::Model::App::View",
  { "foreign.ad_zone_id" => "self.ad_zone_id" },
);


# Created by DBIx::Class::Schema::Loader v0.04999_07 @ 2009-06-14 16:15:26
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:mRsad2KvZT5BELMl4xCHmQ


# You can replace this text with custom content, and it will be preserved on regeneration
1;
