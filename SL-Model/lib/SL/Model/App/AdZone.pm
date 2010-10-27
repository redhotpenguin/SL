package SL::Model::App::AdZone;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';

__PACKAGE__->load_components("InflateColumn::DateTime");

=head1 NAME

SL::Model::App::AdZone

=cut

__PACKAGE__->table("ad_zone");

=head1 ACCESSORS

=head2 ad_zone_id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0
  sequence: 'ad_zone_ad_zone_id_seq'

=head2 code

  data_type: 'text'
  is_nullable: 0

=head2 name

  data_type: 'text'
  is_nullable: 0

=head2 account_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 ad_size_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 active

  data_type: 'boolean'
  default_value: true
  is_nullable: 0

=head2 reg_id

  data_type: 'integer'
  default_value: 1
  is_foreign_key: 1
  is_nullable: 0

=head2 code_double

  data_type: 'text'
  is_nullable: 1

=head2 public

  data_type: 'boolean'
  default_value: false
  is_nullable: 0

=head2 mts

  data_type: 'timestamp without time zone'
  default_value: now()
  is_nullable: 1

=head2 hidden

  data_type: 'boolean'
  default_value: false
  is_nullable: 0

=head2 is_default

  data_type: 'boolean'
  default_value: false
  is_nullable: 0

=head2 image_href

  data_type: 'text'
  is_nullable: 1

=head2 link_href

  data_type: 'text'
  is_nullable: 1

=head2 weight

  data_type: 'integer'
  default_value: 1
  is_nullable: 1

=head2 insertions_yesterday

  data_type: 'integer'
  default_value: 0
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "ad_zone_id",
  {
    data_type         => "integer",
    is_auto_increment => 1,
    is_nullable       => 0,
    sequence          => "ad_zone_ad_zone_id_seq",
  },
  "code",
  { data_type => "text", is_nullable => 0 },
  "name",
  { data_type => "text", is_nullable => 0 },
  "account_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "ad_size_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "active",
  { data_type => "boolean", default_value => \"true", is_nullable => 0 },
  "reg_id",
  {
    data_type      => "integer",
    default_value  => 1,
    is_foreign_key => 1,
    is_nullable    => 0,
  },
  "code_double",
  { data_type => "text", is_nullable => 1 },
  "public",
  { data_type => "boolean", default_value => \"false", is_nullable => 0 },
  "mts",
  {
    data_type     => "timestamp without time zone",
    default_value => \"now()",
    is_nullable   => 1,
  },
  "hidden",
  { data_type => "boolean", default_value => \"false", is_nullable => 0 },
  "is_default",
  { data_type => "boolean", default_value => \"false", is_nullable => 0 },
  "image_href",
  { data_type => "text", is_nullable => 1 },
  "link_href",
  { data_type => "text", is_nullable => 1 },
  "weight",
  { data_type => "integer", default_value => 1, is_nullable => 1 },
  "insertions_yesterday",
  { data_type => "integer", default_value => 0, is_nullable => 0 },
);
__PACKAGE__->set_primary_key("ad_zone_id");

=head1 RELATIONS

=head2 reg

Type: belongs_to

Related object: L<SL::Model::App::Reg>

=cut

__PACKAGE__->belongs_to(
  "reg",
  "SL::Model::App::Reg",
  { reg_id => "reg_id" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "CASCADE" },
);

=head2 ad_size

Type: belongs_to

Related object: L<SL::Model::App::AdSize>

=cut

__PACKAGE__->belongs_to(
  "ad_size",
  "SL::Model::App::AdSize",
  { ad_size_id => "ad_size_id" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "CASCADE" },
);

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

=head2 router_ad_zones

Type: has_many

Related object: L<SL::Model::App::RouterAdZone>

=cut

__PACKAGE__->has_many(
  "router_ad_zones",
  "SL::Model::App::RouterAdZone",
  { "foreign.ad_zone_id" => "self.ad_zone_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 views

Type: has_many

Related object: L<SL::Model::App::View>

=cut

__PACKAGE__->has_many(
  "views",
  "SL::Model::App::View",
  { "foreign.ad_zone_id" => "self.ad_zone_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);


# Created by DBIx::Class::Schema::Loader v0.06001 @ 2010-09-02 12:45:09
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:OK7rOOZPXc33XWrHQ7n23A
# These lines were loaded from '/Users/phred/dev/perl-5.12.0/lib/site_perl/5.12.0/SL/Model/App/AdZone.pm' found in @INC.
# They are now part of the custom portion of this file
# for you to hand-edit.  If you do not either delete
# this section or remove that file from @INC, this section
# will be repeated redundantly when you re-create this
# file again via Loader!  See skip_load_external to disable
# this feature.
# You can replace this text with custom content, and it will be preserved on regeneration
1;
