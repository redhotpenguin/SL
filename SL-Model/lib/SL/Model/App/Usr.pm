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

  data_type: 'timestamp without time zone'
  default_value: now()
  is_nullable: 1

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
    data_type     => "timestamp without time zone",
    default_value => \"now()",
    is_nullable   => 1,
  },
  "name",
  { data_type => "text", is_nullable => 1 },
  "email",
  { data_type => "text", is_nullable => 1 },
);
__PACKAGE__->set_primary_key("usr_id");


# Created by DBIx::Class::Schema::Loader v0.06001 @ 2010-09-02 12:45:09
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:YjTu0QfDLaUm3OaIsVWwtQ
# These lines were loaded from '/Users/phred/dev/perl-5.12.0/lib/site_perl/5.12.0/SL/Model/App/Usr.pm' found in @INC.
# They are now part of the custom portion of this file
# for you to hand-edit.  If you do not either delete
# this section or remove that file from @INC, this section
# will be repeated redundantly when you re-create this
# file again via Loader!  See skip_load_external to disable
# this feature.
# You can replace this text with custom content, and it will be preserved on regeneration
#
1;
