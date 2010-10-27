package SL::Model::App::AdSize;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';

__PACKAGE__->load_components("InflateColumn::DateTime");

=head1 NAME

SL::Model::App::AdSize

=cut

__PACKAGE__->table("ad_size");

=head1 ACCESSORS

=head2 ad_size_id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0
  sequence: 'ad_size_ad_size_id_seq'

=head2 name

  data_type: 'text'
  is_nullable: 1

=head2 css_url

  data_type: 'text'
  is_nullable: 0

=head2 template

  data_type: 'text'
  default_value: (empty string)
  is_nullable: 0

=head2 grouping

  data_type: 'integer'
  default_value: 1
  is_nullable: 0

=head2 js_url

  data_type: 'text'
  default_value: (empty string)
  is_nullable: 0

=head2 head_html

  data_type: 'text'
  is_nullable: 1

=head2 persistent

  data_type: 'boolean'
  default_value: true
  is_nullable: 0

=head2 hidden

  data_type: 'boolean'
  default_value: false
  is_nullable: 0

=head2 height

  data_type: 'integer'
  default_value: 0
  is_nullable: 0

=head2 width

  data_type: 'integer'
  default_value: 0
  is_nullable: 0

=head2 swap

  data_type: 'boolean'
  default_value: false
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "ad_size_id",
  {
    data_type         => "integer",
    is_auto_increment => 1,
    is_nullable       => 0,
    sequence          => "ad_size_ad_size_id_seq",
  },
  "name",
  { data_type => "text", is_nullable => 1 },
  "css_url",
  { data_type => "text", is_nullable => 0 },
  "template",
  { data_type => "text", default_value => "", is_nullable => 0 },
  "grouping",
  { data_type => "integer", default_value => 1, is_nullable => 0 },
  "js_url",
  { data_type => "text", default_value => "", is_nullable => 0 },
  "head_html",
  { data_type => "text", is_nullable => 1 },
  "persistent",
  { data_type => "boolean", default_value => \"true", is_nullable => 0 },
  "hidden",
  { data_type => "boolean", default_value => \"false", is_nullable => 0 },
  "height",
  { data_type => "integer", default_value => 0, is_nullable => 0 },
  "width",
  { data_type => "integer", default_value => 0, is_nullable => 0 },
  "swap",
  { data_type => "boolean", default_value => \"false", is_nullable => 1 },
);
__PACKAGE__->set_primary_key("ad_size_id");

=head1 RELATIONS

=head2 ad_zones

Type: has_many

Related object: L<SL::Model::App::AdZone>

=cut

__PACKAGE__->has_many(
  "ad_zones",
  "SL::Model::App::AdZone",
  { "foreign.ad_size_id" => "self.ad_size_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);


# Created by DBIx::Class::Schema::Loader v0.06001 @ 2010-09-02 12:45:09
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:em2Cg87AbcxKQ8R8NtxvlQ
# These lines were loaded from '/Users/phred/dev/perl-5.12.0/lib/site_perl/5.12.0/SL/Model/App/AdSize.pm' found in @INC.
# They are now part of the custom portion of this file
# for you to hand-edit.  If you do not either delete
# this section or remove that file from @INC, this section
# will be repeated redundantly when you re-create this
# file again via Loader!  See skip_load_external to disable
# this feature.

# You can replace this text with custom content, and it will be preserved on regeneration
1;
