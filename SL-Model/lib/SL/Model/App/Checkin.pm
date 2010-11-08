package SL::Model::App::Checkin;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';

__PACKAGE__->load_components("InflateColumn::DateTime");

=head1 NAME

SL::Model::App::Checkin

=cut

__PACKAGE__->table("checkin");

=head1 ACCESSORS

=head2 checkin_id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0
  sequence: 'checkin_checkin_id_seq'

=head2 router_id

  data_type: 'integer'
  default_value: 1
  is_foreign_key: 1
  is_nullable: 0

=head2 memfree

  data_type: 'integer'
  default_value: 0
  is_nullable: 0

=head2 users

  data_type: 'integer'
  default_value: 0
  is_nullable: 0

=head2 kbup

  data_type: 'integer'
  default_value: 0
  is_nullable: 0

=head2 kbdown

  data_type: 'integer'
  default_value: 0
  is_nullable: 0

=head2 cts

  data_type: 'timestamp'
  default_value: current_timestamp
  is_nullable: 1
  original: {default_value => \"now()"}

=head2 nodes

  data_type: 'text'
  default_value: (empty string)
  is_nullable: 0

=head2 nodes_rssi

  data_type: 'text'
  default_value: (empty string)
  is_nullable: 0

=head2 ping_ms

  data_type: 'integer'
  default_value: 0
  is_nullable: 0

=head2 speed_kbytes

  data_type: 'integer'
  default_value: 0
  is_nullable: 0

=head2 hops

  data_type: 'integer'
  default_value: 0
  is_nullable: 0

=head2 gateway_quality

  data_type: 'integer'
  default_value: 0
  is_nullable: 0

=head2 load

  data_type: 'text'
  default_value: 0
  is_nullable: 0

=head2 nodogs

  data_type: 'integer'
  default_value: 0
  is_nullable: 0

=head2 tcpconns

  data_type: 'integer'
  default_value: 0
  is_nullable: 0

=head2 robin

  data_type: 'text'
  default_value: (empty string)
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "checkin_id",
  {
    data_type         => "integer",
    is_auto_increment => 1,
    is_nullable       => 0,
    sequence          => "checkin_checkin_id_seq",
  },
  "router_id",
  {
    data_type      => "integer",
    default_value  => 1,
    is_foreign_key => 1,
    is_nullable    => 0,
  },
  "memfree",
  { data_type => "integer", default_value => 0, is_nullable => 0 },
  "users",
  { data_type => "integer", default_value => 0, is_nullable => 0 },
  "kbup",
  { data_type => "integer", default_value => 0, is_nullable => 0 },
  "kbdown",
  { data_type => "integer", default_value => 0, is_nullable => 0 },
  "cts",
  {
    data_type     => "timestamp",
    default_value => \"current_timestamp",
    is_nullable   => 1,
    original      => { default_value => \"now()" },
  },
  "nodes",
  { data_type => "text", default_value => "", is_nullable => 0 },
  "nodes_rssi",
  { data_type => "text", default_value => "", is_nullable => 0 },
  "ping_ms",
  { data_type => "integer", default_value => 0, is_nullable => 0 },
  "speed_kbytes",
  { data_type => "integer", default_value => 0, is_nullable => 0 },
  "hops",
  { data_type => "integer", default_value => 0, is_nullable => 0 },
  "gateway_quality",
  { data_type => "integer", default_value => 0, is_nullable => 0 },
  "load",
  { data_type => "text", default_value => 0, is_nullable => 0 },
  "nodogs",
  { data_type => "integer", default_value => 0, is_nullable => 0 },
  "tcpconns",
  { data_type => "integer", default_value => 0, is_nullable => 0 },
  "robin",
  { data_type => "text", default_value => "", is_nullable => 0 },
);
__PACKAGE__->set_primary_key("checkin_id");

=head1 RELATIONS

=head2 router

Type: belongs_to

Related object: L<SL::Model::App::Router>

=cut

__PACKAGE__->belongs_to(
  "router",
  "SL::Model::App::Router",
  { router_id => "router_id" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "CASCADE" },
);


# Created by DBIx::Class::Schema::Loader v0.07002 @ 2010-11-08 15:50:46
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:bkE3Dt2IZZAHvI1OogYVtQ


1;

