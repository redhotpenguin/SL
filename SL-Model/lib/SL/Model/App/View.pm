package SL::Model::App::View;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';

__PACKAGE__->load_components("InflateColumn::DateTime");

=head1 NAME

SL::Model::App::View

=cut

__PACKAGE__->table("view");

=head1 ACCESSORS

=head2 view_id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0
  sequence: 'view_view_id_seq'

=head2 ad_zone_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 cts

  data_type: 'timestamp without time zone'
  default_value: now()
  is_nullable: 1

=head2 ip

  data_type: 'inet'
  is_nullable: 1

=head2 url

  data_type: 'text'
  default_value: (empty string)
  is_nullable: 1

=head2 referer

  data_type: 'text'
  default_value: (empty string)
  is_nullable: 1

=head2 usr_id

  data_type: 'character varying'
  default_value: 1
  is_nullable: 1
  size: 8

=head2 router_id

  data_type: 'integer'
  default_value: 1
  is_foreign_key: 1
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "view_id",
  {
    data_type         => "integer",
    is_auto_increment => 1,
    is_nullable       => 0,
    sequence          => "view_view_id_seq",
  },
  "ad_zone_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "cts",
  {
    data_type     => "timestamp without time zone",
    default_value => \"now()",
    is_nullable   => 1,
  },
  "ip",
  { data_type => "inet", is_nullable => 1 },
  "url",
  { data_type => "text", default_value => "", is_nullable => 1 },
  "referer",
  { data_type => "text", default_value => "", is_nullable => 1 },
  "usr_id",
  {
    data_type => "character varying",
    default_value => 1,
    is_nullable => 1,
    size => 8,
  },
  "router_id",
  {
    data_type      => "integer",
    default_value  => 1,
    is_foreign_key => 1,
    is_nullable    => 1,
  },
);
__PACKAGE__->set_primary_key("view_id");

=head1 RELATIONS

=head2 router

Type: belongs_to

Related object: L<SL::Model::App::Router>

=cut

__PACKAGE__->belongs_to(
  "router",
  "SL::Model::App::Router",
  { router_id => "router_id" },
  {
    is_deferrable => 1,
    join_type     => "LEFT",
    on_delete     => "CASCADE",
    on_update     => "CASCADE",
  },
);

=head2 ad_zone

Type: belongs_to

Related object: L<SL::Model::App::AdZone>

=cut

__PACKAGE__->belongs_to(
  "ad_zone",
  "SL::Model::App::AdZone",
  { ad_zone_id => "ad_zone_id" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "CASCADE" },
);


# Created by DBIx::Class::Schema::Loader v0.06001 @ 2010-09-02 12:45:09
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:ELNvLWLVn/OheqjgVd02Dg
# These lines were loaded from '/Users/phred/dev/perl-5.12.0/lib/site_perl/5.12.0/SL/Model/App/View.pm' found in @INC.
# They are now part of the custom portion of this file
# for you to hand-edit.  If you do not either delete
# this section or remove that file from @INC, this section
# will be repeated redundantly when you re-create this
# file again via Loader!  See skip_load_external to disable
# this feature.

# You can replace this text with custom content, and it will be preserved on regeneration
1;
