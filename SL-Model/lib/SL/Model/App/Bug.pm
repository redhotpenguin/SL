package SL::Model::App::Bug;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("InflateColumn::DateTime", "Core");
__PACKAGE__->table("bug");
__PACKAGE__->add_columns(
  "bug_id",
  {
    data_type => "integer",
    default_value => "nextval('bug_bug_id_seq'::regclass)",
    is_auto_increment => 1,
    is_nullable => 0,
    size => 4,
  },
  "image_href",
  {
    data_type => "text",
    default_value => undef,
    is_nullable => 0,
    size => undef,
  },
  "link_href",
  {
    data_type => "text",
    default_value => undef,
    is_nullable => 0,
    size => undef,
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
);
__PACKAGE__->set_primary_key("bug_id");
__PACKAGE__->has_many(
  "ad_zones",
  "SL::Model::App::AdZone",
  { "foreign.bug_id" => "self.bug_id" },
);
__PACKAGE__->belongs_to(
  "account",
  "SL::Model::App::Account",
  { account_id => "account_id" },
);
__PACKAGE__->belongs_to(
  "ad_size",
  "SL::Model::App::AdSize",
  { ad_size_id => "ad_size_id" },
);


# Created by DBIx::Class::Schema::Loader v0.04999_07 @ 2009-06-14 16:15:26
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:UQQx3wfU14ghGKGbI4VvpA


# You can replace this text with custom content, and it will be preserved on regeneration
1;
