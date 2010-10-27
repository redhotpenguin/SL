package SL::Model::App::Forgot;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';

__PACKAGE__->load_components("InflateColumn::DateTime");

=head1 NAME

SL::Model::App::Forgot

=cut

__PACKAGE__->table("forgot");

=head1 ACCESSORS

=head2 forgot_id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0
  sequence: 'forgot_forgot_id_seq'

=head2 reg_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 ts

  data_type: 'timestamp without time zone'
  default_value: now()
  is_nullable: 1

=head2 link_md5

  data_type: 'character varying'
  is_nullable: 0
  size: 32

=head2 expired

  data_type: 'boolean'
  default_value: false
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "forgot_id",
  {
    data_type         => "integer",
    is_auto_increment => 1,
    is_nullable       => 0,
    sequence          => "forgot_forgot_id_seq",
  },
  "reg_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "ts",
  {
    data_type     => "timestamp without time zone",
    default_value => \"now()",
    is_nullable   => 1,
  },
  "link_md5",
  { data_type => "character varying", is_nullable => 0, size => 32 },
  "expired",
  { data_type => "boolean", default_value => \"false", is_nullable => 1 },
);
__PACKAGE__->set_primary_key("forgot_id");

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


# Created by DBIx::Class::Schema::Loader v0.06001 @ 2010-09-02 12:45:09
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:DRK1d2jHOnhf7DHR8TbvCA
# These lines were loaded from '/Users/phred/dev/perl-5.12.0/lib/site_perl/5.12.0/SL/Model/App/Forgot.pm' found in @INC.
# They are now part of the custom portion of this file
# for you to hand-edit.  If you do not either delete
# this section or remove that file from @INC, this section
# will be repeated redundantly when you re-create this
# file again via Loader!  See skip_load_external to disable
# this feature.
# You can replace this text with custom content, and it will be preserved on regeneration
1;
