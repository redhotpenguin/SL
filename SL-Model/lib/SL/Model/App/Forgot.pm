package SL::Model::App::Forgot;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("InflateColumn::DateTime", "Core");
__PACKAGE__->table("forgot");
__PACKAGE__->add_columns(
  "forgot_id",
  {
    data_type => "integer",
    default_value => "nextval('forgot_forgot_id_seq'::regclass)",
    is_auto_increment => 1,
    is_nullable => 0,
    size => 4,
  },
  "reg_id",
  {
    data_type => "integer",
    default_value => undef,
    is_foreign_key => 1,
    is_nullable => 0,
    size => 4,
  },
  "ts",
  {
    data_type => "timestamp without time zone",
    default_value => "now()",
    is_nullable => 1,
    size => 8,
  },
  "link_md5",
  {
    data_type => "character varying",
    default_value => undef,
    is_nullable => 0,
    size => 32,
  },
  "expired",
  {
    data_type => "boolean",
    default_value => "false",
    is_nullable => 1,
    size => 1,
  },
);
__PACKAGE__->set_primary_key("forgot_id");
__PACKAGE__->belongs_to("reg", "SL::Model::App::Reg", { reg_id => "reg_id" });


# Created by DBIx::Class::Schema::Loader v0.04999_07 @ 2009-06-14 16:15:26
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:nMDm4OHRkKw8F7o/S0+lTg


# You can replace this text with custom content, and it will be preserved on regeneration
1;
