package SL::Model::App::SearchUser;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';

__PACKAGE__->load_components("InflateColumn::DateTime");

=head1 NAME

SL::Model::App::SearchUser

=cut

__PACKAGE__->table("search_user");

=head1 ACCESSORS

=head2 search_user_id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0
  sequence: 'search_user_search_user_id_seq'

=head2 user_agent

  data_type: 'text'
  is_nullable: 0

=head2 tos

  data_type: 'boolean'
  default_value: false
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "search_user_id",
  {
    data_type         => "integer",
    is_auto_increment => 1,
    is_nullable       => 0,
    sequence          => "search_user_search_user_id_seq",
  },
  "user_agent",
  { data_type => "text", is_nullable => 0 },
  "tos",
  { data_type => "boolean", default_value => \"false", is_nullable => 1 },
);
__PACKAGE__->set_primary_key("search_user_id");


# Created by DBIx::Class::Schema::Loader v0.07002 @ 2010-11-08 15:50:46
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:vdCbZxGOrMKcTPMfy06DrA


# You can replace this text with custom content, and it will be preserved on regeneration
1;
