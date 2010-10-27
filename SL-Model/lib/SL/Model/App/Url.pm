package SL::Model::App::Url;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';

__PACKAGE__->load_components("InflateColumn::DateTime");

=head1 NAME

SL::Model::App::Url

=cut

__PACKAGE__->table("url");

=head1 ACCESSORS

=head2 url_id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0
  sequence: 'url_url_id_seq'

=head2 url

  data_type: 'character varying'
  is_nullable: 1
  size: 256

=head2 blacklisted

  data_type: 'boolean'
  default_value: true
  is_nullable: 1

=head2 reg_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 ts

  data_type: 'timestamp without time zone'
  default_value: now()
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "url_id",
  {
    data_type         => "integer",
    is_auto_increment => 1,
    is_nullable       => 0,
    sequence          => "url_url_id_seq",
  },
  "url",
  { data_type => "character varying", is_nullable => 1, size => 256 },
  "blacklisted",
  { data_type => "boolean", default_value => \"true", is_nullable => 1 },
  "reg_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "ts",
  {
    data_type     => "timestamp without time zone",
    default_value => \"now()",
    is_nullable   => 1,
  },
);
__PACKAGE__->set_primary_key("url_id");
__PACKAGE__->add_unique_constraint("url_uniq_index", ["url"]);

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
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:IA6P097UsvOgx1Runbplyw
# These lines were loaded from '/Users/phred/dev/perl-5.12.0/lib/site_perl/5.12.0/SL/Model/App/Url.pm' found in @INC.
# They are now part of the custom portion of this file
# for you to hand-edit.  If you do not either delete
# this section or remove that file from @INC, this section
# will be repeated redundantly when you re-create this
# file again via Loader!  See skip_load_external to disable
# this feature.
# You can replace this text with custom content, and it will be preserved on regeneration
1;
