package SL::Model::App::RouterAdZone;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("InflateColumn::DateTime", "Core");
__PACKAGE__->table("router__ad_zone");
__PACKAGE__->add_columns(
  "router_id",
  {
    data_type => "integer",
    default_value => undef,
    is_foreign_key => 1,
    is_nullable => 0,
    size => 4,
  },
  "ad_zone_id",
  {
    data_type => "integer",
    default_value => undef,
    is_foreign_key => 1,
    is_nullable => 0,
    size => 4,
  },
);
__PACKAGE__->set_primary_key("router_id", "ad_zone_id");
__PACKAGE__->belongs_to(
  "ad_zone",
  "SL::Model::App::AdZone",
  { ad_zone_id => "ad_zone_id" },
);
__PACKAGE__->belongs_to(
  "router",
  "SL::Model::App::Router",
  { router_id => "router_id" },
);


# Created by DBIx::Class::Schema::Loader v0.04999_07 @ 2009-06-14 16:15:26
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:syVp1lvZEtXhYW7I0AqsiA


# You can replace this text with custom content, and it will be preserved on regeneration
1;
