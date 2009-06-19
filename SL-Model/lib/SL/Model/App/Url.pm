package SL::Model::App::Url;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("InflateColumn::DateTime", "Core");
__PACKAGE__->table("url");
__PACKAGE__->add_columns(
  "url_id",
  {
    data_type => "integer",
    default_value => "nextval('url_url_id_seq'::regclass)",
    is_auto_increment => 1,
    is_nullable => 0,
    size => 4,
  },
  "url",
  {
    data_type => "character varying",
    default_value => undef,
    is_nullable => 1,
    size => 256,
  },
  "blacklisted",
  {
    data_type => "boolean",
    default_value => "true",
    is_nullable => 1,
    size => 1,
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
);
__PACKAGE__->set_primary_key("url_id");
__PACKAGE__->add_unique_constraint("url_uniq_index", ["url"]);
__PACKAGE__->belongs_to("reg", "SL::Model::App::Reg", { reg_id => "reg_id" });


# Created by DBIx::Class::Schema::Loader v0.04999_07 @ 2009-06-14 16:15:26
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:IwLXMHTjTGDWXpNEUKxqsw


# You can replace this text with custom content, and it will be preserved on regeneration
1;
