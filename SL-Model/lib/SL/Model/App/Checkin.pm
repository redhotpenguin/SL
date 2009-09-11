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
  "ping_ms",
  { data_type => "integer", default_value => 0, is_nullable => 0, size => 4 },
  "speed_kbytes",
  { data_type => "integer", default_value => 0, is_nullable => 0, size => 4 },
  "hops",
  { data_type => "integer", default_value => 0, is_nullable => 0, size => 4 },
  "nodes",
  {
    data_type => "text",
    default_value => "''::text",
    is_nullable => 0,
    size => undef,
  },
  "nodes_rssi",
  {
    data_type => "text",
    default_value => "''::text",
    is_nullable => 0,
    size => undef,
  },
);
__PACKAGE__->set_primary_key("checkin_id");
__PACKAGE__->belongs_to(
  "router",
  "SL::Model::App::Router",
  { router_id => "router_id" },
);


# Created by DBIx::Class::Schema::Loader v0.04999_08 @ 2009-09-10 23:29:29
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:7PcWA4fsrJhQ+P56qK+2CQ
# These lines were loaded from '/home/phred/dev/perl/lib/site_perl/5.8.9/SL/Model/App/Checkin.pm' found in @INC.
# They are now part of the custom portion of this file
# for you to hand-edit.  If you do not either delete
# this section or remove that file from @INC, this section
# will be repeated redundantly when you re-create this
# file again via Loader!


# End of lines loaded from '/home/phred/dev/perl/lib/site_perl/5.8.9/SL/Model/App/Checkin.pm' 


# You can replace this text with custom content, and it will be preserved on regeneration
1;
