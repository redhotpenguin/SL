package SL::Model::App::AdSize;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("InflateColumn::DateTime", "Core");
__PACKAGE__->table("ad_size");
__PACKAGE__->add_columns(
  "ad_size_id",
  {
    data_type => "integer",
    default_value => "nextval('ad_size_ad_size_id_seq'::regclass)",
    is_auto_increment => 1,
    is_nullable => 0,
    size => 4,
  },
  "name",
  {
    data_type => "text",
    default_value => undef,
    is_nullable => 1,
    size => undef,
  },
  "css_url",
  {
    data_type => "text",
    default_value => undef,
    is_nullable => 0,
    size => undef,
  },
  "template",
  {
    data_type => "text",
    default_value => "''::text",
    is_nullable => 0,
    size => undef,
  },
  "grouping",
  { data_type => "integer", default_value => 1, is_nullable => 0, size => 4 },
  "js_url",
  {
    data_type => "text",
    default_value => "''::text",
    is_nullable => 0,
    size => undef,
  },
  "head_html",
  {
    data_type => "text",
    default_value => undef,
    is_nullable => 1,
    size => undef,
  },
  "persistent",
  {
    data_type => "boolean",
    default_value => "true",
    is_nullable => 0,
    size => 1,
  },
  "hidden",
  {
    data_type => "boolean",
    default_value => "false",
    is_nullable => 0,
    size => 1,
  },
  "height",
  { data_type => "integer", default_value => 0, is_nullable => 0, size => 4 },
  "width",
  { data_type => "integer", default_value => 0, is_nullable => 0, size => 4 },
  "swap",
  {
    data_type => "boolean",
    default_value => "false",
    is_nullable => 0,
    size => 1,
  },
);
__PACKAGE__->set_primary_key("ad_size_id");
__PACKAGE__->has_many(
  "ad_zones",
  "SL::Model::App::AdZone",
  { "foreign.ad_size_id" => "self.ad_size_id" },
);


# Created by DBIx::Class::Schema::Loader v0.04999_07 @ 2009-06-14 16:15:26
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:9o6GvWxfRaqeu+A8/w+YTw


# You can replace this text with custom content, and it will be preserved on regeneration
1;
