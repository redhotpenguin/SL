package SL::Model::App::Usr;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("InflateColumn::DateTime", "Core");
__PACKAGE__->table("usr");
__PACKAGE__->add_columns(
  "usr_id",
  {
    data_type => "integer",
    default_value => "nextval('usr_usr_id_seq'::regclass)",
    is_auto_increment => 1,
    is_nullable => 0,
    size => 4,
  },
  "hash_mac",
  {
    data_type => "text",
    default_value => "'ffffff'::text",
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
  "name",
  {
    data_type => "text",
    default_value => undef,
    is_nullable => 1,
    size => undef,
  },
  "email",
  {
    data_type => "text",
    default_value => undef,
    is_nullable => 1,
    size => undef,
  },
);
__PACKAGE__->set_primary_key("usr_id");


# Created by DBIx::Class::Schema::Loader v0.04999_07 @ 2009-06-14 16:15:26
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:1e9IR9/hwi7xbbDfCXGfIw


# You can replace this text with custom content, and it will be preserved on regeneration
1;
