package SL::Model::App::UserBlacklist;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';

__PACKAGE__->load_components("InflateColumn::DateTime");

=head1 NAME

SL::Model::App::UserBlacklist

=cut

__PACKAGE__->table("user_blacklist");

=head1 ACCESSORS

=head2 user_id

  data_type: 'character varying'
  is_nullable: 0
  size: 256

=head2 ts

  data_type: 'timestamp without time zone'
  default_value: now()
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "user_id",
  { data_type => "character varying", is_nullable => 0, size => 256 },
  "ts",
  {
    data_type     => "timestamp without time zone",
    default_value => \"now()",
    is_nullable   => 1,
  },
);
__PACKAGE__->set_primary_key("user_id");

# You can replace this text with custom content, and it will be preserved on regeneration
1;
