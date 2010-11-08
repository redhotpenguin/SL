package SL::Model::App::Usr;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';

__PACKAGE__->load_components("InflateColumn::DateTime");

=head1 NAME

SL::Model::App::Usr

=cut

__PACKAGE__->table("usr");

=head1 ACCESSORS

=head2 usr_id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0
  sequence: 'usr_usr_id_seq'

=head2 hash_mac

  data_type: 'text'
  default_value: 'ffffff'
  is_nullable: 0

=head2 cts

  data_type: 'timestamp'
  default_value: current_timestamp
  is_nullable: 1
  original: {default_value => \"now()"}

=head2 name

  data_type: 'text'
  is_nullable: 1

=head2 email

  data_type: 'text'
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "usr_id",
  {
    data_type         => "integer",
    is_auto_increment => 1,
    is_nullable       => 0,
    sequence          => "usr_usr_id_seq",
  },
  "hash_mac",
  { data_type => "text", default_value => "ffffff", is_nullable => 0 },
  "cts",
  {
    data_type     => "timestamp",
    default_value => \"current_timestamp",
    is_nullable   => 1,
    original      => { default_value => \"now()" },
  },
  "name",
  { data_type => "text", is_nullable => 1 },
  "email",
  { data_type => "text", is_nullable => 1 },
);
__PACKAGE__->set_primary_key("usr_id");


# Created by DBIx::Class::Schema::Loader v0.07002 @ 2010-11-08 15:50:46
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:C9xXKRH38zuQTwsOusPZLA

# You can replace this text with custom content, and it will be preserved on regeneration
#
1;
