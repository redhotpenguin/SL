package SL::Model::App::UserBlacklist;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("InflateColumn::DateTime", "Core");
__PACKAGE__->table("user_blacklist");
__PACKAGE__->add_columns(
  "user_id",
  {
    data_type => "character varying",
    default_value => undef,
    is_nullable => 0,
    size => 256,
  },
  "ts",
  {
    data_type => "timestamp without time zone",
    default_value => "now()",
    is_nullable => 1,
    size => 8,
  },
);
__PACKAGE__->set_primary_key("user_id");


# Created by DBIx::Class::Schema::Loader v0.04999_07 @ 2009-06-14 16:15:26
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:qbWwgY6OSeRQ46YbmWRBBQ


# You can replace this text with custom content, and it will be preserved on regeneration
1;
