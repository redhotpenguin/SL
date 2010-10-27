package SL::Model::App::RouterAdZone;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';

__PACKAGE__->load_components("InflateColumn::DateTime");

=head1 NAME

SL::Model::App::RouterAdZone

=cut

__PACKAGE__->table("router__ad_zone");

=head1 ACCESSORS

=head2 router_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 ad_zone_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "router_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "ad_zone_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
);
__PACKAGE__->set_primary_key("router_id", "ad_zone_id");

=head1 RELATIONS

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

=head2 router

Type: belongs_to

Related object: L<SL::Model::App::Router>

=cut

__PACKAGE__->belongs_to(
  "router",
  "SL::Model::App::Router",
  { router_id => "router_id" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "CASCADE" },
);


# Created by DBIx::Class::Schema::Loader v0.06001 @ 2010-09-02 12:45:09
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:KBQZvG4qposZD/jRqygQsw
# These lines were loaded from '/Users/phred/dev/perl-5.12.0/lib/site_perl/5.12.0/SL/Model/App/RouterAdZone.pm' found in @INC.
# They are now part of the custom portion of this file
# for you to hand-edit.  If you do not either delete
# this section or remove that file from @INC, this section
# will be repeated redundantly when you re-create this
# file again via Loader!  See skip_load_external to disable
# this feature.
# You can replace this text with custom content, and it will be preserved on regeneration
1;
