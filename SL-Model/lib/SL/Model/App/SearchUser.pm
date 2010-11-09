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

=head2 uuid

  data_type: 'text'
  is_nullable: 0

=head2 tos

  data_type: 'integer'
  default_value: 0
  is_nullable: 0

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
  "uuid",
  { data_type => "text", is_nullable => 0 },
  "tos",
  { data_type => "integer", default_value => 0, is_nullable => 0 },
);
__PACKAGE__->set_primary_key("search_user_id");

=head1 RELATIONS

=head2 searches

Type: has_many

Related object: L<SL::Model::App::Search>

=cut

__PACKAGE__->has_many(
  "searches",
  "SL::Model::App::Search",
  { "foreign.search_user_id" => "self.search_user_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);


# Created by DBIx::Class::Schema::Loader v0.07002 @ 2010-11-08 16:57:04
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:neA4QrrCA6Fu8cKyDUz0RA

use Data::UUID;

our $Ug = Data::UUID->new;

sub new {
    my ($class, $attrs) = @_;

    my $uuid = $Ug->create();

    $attrs->{uuid} = $Ug->to_string($uuid);

    my $new = $class->next::method($attrs);
    return $new;
}

1;
