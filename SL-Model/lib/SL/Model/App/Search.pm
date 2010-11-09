package SL::Model::App::Search;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';

__PACKAGE__->load_components("InflateColumn::DateTime");

=head1 NAME

SL::Model::App::Search

=cut

__PACKAGE__->table("search");

=head1 ACCESSORS

=head2 search_id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0
  sequence: 'search_search_id_seq'

=head2 query

  data_type: 'text'
  is_nullable: 0

=head2 start

  data_type: 'smallint'
  is_nullable: 0

=head2 duration

  data_type: 'numeric'
  is_nullable: 0
  size: [4,2]

=head2 network_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 search_user_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 mts

  data_type: 'timestamp'
  default_value: current_timestamp
  is_nullable: 1
  original: {default_value => \"now()"}

=cut

__PACKAGE__->add_columns(
  "search_id",
  {
    data_type         => "integer",
    is_auto_increment => 1,
    is_nullable       => 0,
    sequence          => "search_search_id_seq",
  },
  "query",
  { data_type => "text", is_nullable => 0 },
  "start",
  { data_type => "smallint", is_nullable => 0 },
  "duration",
  { data_type => "numeric", is_nullable => 0, size => [4, 2] },
  "network_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "search_user_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "mts",
  {
    data_type     => "timestamp",
    default_value => \"current_timestamp",
    is_nullable   => 1,
    original      => { default_value => \"now()" },
  },
);

=head1 RELATIONS

=head2 network

Type: belongs_to

Related object: L<SL::Model::App::Network>

=cut

__PACKAGE__->belongs_to(
  "network",
  "SL::Model::App::Network",
  { network_id => "network_id" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "CASCADE" },
);

=head2 search_user

Type: belongs_to

Related object: L<SL::Model::App::SearchUser>

=cut

__PACKAGE__->belongs_to(
  "search_user",
  "SL::Model::App::SearchUser",
  { search_user_id => "search_user_id" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "CASCADE" },
);


# Created by DBIx::Class::Schema::Loader v0.07002 @ 2010-11-08 17:16:12
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:P3TTH5Lbm+TkuDrzE2QzWg

# You can replace this text with custom content, and it will be preserved on regeneration
1;
