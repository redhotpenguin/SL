package SL::Model::App::Network;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';

__PACKAGE__->load_components("InflateColumn::DateTime");

=head1 NAME

SL::Model::App::Network

=cut

__PACKAGE__->table("network");

=head1 ACCESSORS

=head2 network_id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0
  sequence: 'network_network_id_seq'

=head2 cts

  data_type: 'timestamp without time zone'
  default_value: now()
  is_nullable: 1

=head2 mts

  data_type: 'timestamp without time zone'
  default_value: now()
  is_nullable: 1

=head2 active

  data_type: 'boolean'
  default_value: true
  is_nullable: 1

=head2 description

  data_type: 'text'
  is_nullable: 1

=head2 name

  data_type: 'text'
  is_nullable: 1

=head2 ssid

  data_type: 'text'
  default_value: (empty string)
  is_nullable: 1

=head2 account_id

  data_type: 'integer'
  default_value: 1
  is_foreign_key: 1
  is_nullable: 0

=head2 wan_ip

  data_type: 'inet'
  is_nullable: 1

=head2 notes

  data_type: 'text'
  default_value: (empty string)
  is_nullable: 0

=head2 lat

  data_type: 'double precision'
  is_nullable: 1

=head2 lng

  data_type: 'double precision'
  is_nullable: 1

=head2 searches_daily

  data_type: 'integer'
  default_value: 0
  is_nullable: 0

=head2 users_daily

  data_type: 'integer'
  default_value: 0
  is_nullable: 0

=head2 searches_monthly

  data_type: 'integer'
  default_value: 0
  is_nullable: 0

=head2 users_monthly

  data_type: 'integer'
  default_value: 0
  is_nullable: 0

=head2 street_address

  data_type: 'text'
  default_value: (empty string)
  is_nullable: 1

=head2 city

  data_type: 'text'
  default_value: (empty string)
  is_nullable: 1

=head2 zip

  data_type: 'text'
  default_value: (empty string)
  is_nullable: 1

=head2 state

  data_type: 'text'
  default_value: (empty string)
  is_nullable: 1

=head2 country

  data_type: 'text'
  default_value: (empty string)
  is_nullable: 1

=head2 time_zone

  data_type: 'text'
  default_value: 'America/Los_Angeles'
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "network_id",
  {
    data_type         => "integer",
    is_auto_increment => 1,
    is_nullable       => 0,
    sequence          => "network_network_id_seq",
  },
  "cts",
  {
    data_type     => "timestamp without time zone",
    default_value => \"now()",
    is_nullable   => 1,
  },
  "mts",
  {
    data_type     => "timestamp without time zone",
    default_value => \"now()",
    is_nullable   => 1,
  },
  "active",
  { data_type => "boolean", default_value => \"true", is_nullable => 1 },
  "description",
  { data_type => "text", is_nullable => 1 },
  "name",
  { data_type => "text", is_nullable => 1 },
  "ssid",
  { data_type => "text", default_value => "", is_nullable => 1 },
  "account_id",
  {
    data_type      => "integer",
    default_value  => 1,
    is_foreign_key => 1,
    is_nullable    => 0,
  },
  "wan_ip",
  { data_type => "inet", is_nullable => 1 },
  "notes",
  { data_type => "text", default_value => "", is_nullable => 0 },
  "lat",
  { data_type => "double precision", is_nullable => 1 },
  "lng",
  { data_type => "double precision", is_nullable => 1 },
  "searches_daily",
  { data_type => "integer", default_value => 0, is_nullable => 0 },
  "users_daily",
  { data_type => "integer", default_value => 0, is_nullable => 0 },
  "searches_monthly",
  { data_type => "integer", default_value => 0, is_nullable => 0 },
  "users_monthly",
  { data_type => "integer", default_value => 0, is_nullable => 0 },
  "street_address",
  { data_type => "text", default_value => "", is_nullable => 1 },
  "city",
  { data_type => "text", default_value => "", is_nullable => 1 },
  "zip",
  { data_type => "text", default_value => "", is_nullable => 1 },
  "state",
  { data_type => "text", default_value => "", is_nullable => 1 },
  "country",
  { data_type => "text", default_value => "", is_nullable => 1 },
  "time_zone",
  {
    data_type     => "text",
    default_value => "America/Los_Angeles",
    is_nullable   => 1,
  },
);
__PACKAGE__->set_primary_key("network_id");

=head1 RELATIONS

=head2 account

Type: belongs_to

Related object: L<SL::Model::App::Account>

=cut

__PACKAGE__->belongs_to(
  "account",
  "SL::Model::App::Account",
  { account_id => "account_id" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "CASCADE" },
);


# Created by DBIx::Class::Schema::Loader v0.06001 @ 2010-09-02 12:45:09
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:X4auWfo+k7LDXNUPAacSgA


# You can replace this text with custom content, and it will be preserved on regeneration
1;
