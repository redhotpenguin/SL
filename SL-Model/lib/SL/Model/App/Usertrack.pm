package SL::Model::App::Usertrack;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';

__PACKAGE__->load_components("InflateColumn::DateTime");

=head1 NAME

SL::Model::App::Usertrack

=cut

__PACKAGE__->table("usertrack");

=head1 ACCESSORS

=head2 usertrack_id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0
  sequence: 'usertrack_usertrack_id_seq'

=head2 router_id

  data_type: 'integer'
  default_value: 1
  is_foreign_key: 1
  is_nullable: 0

=head2 totalkb

  data_type: 'integer'
  default_value: 0
  is_nullable: 0

=head2 hostname

  data_type: 'text'
  default_value: (empty string)
  is_nullable: 0

=head2 kbup

  data_type: 'integer'
  default_value: 0
  is_nullable: 0

=head2 kbdown

  data_type: 'integer'
  default_value: 0
  is_nullable: 0

=head2 kbtotal

  data_type: 'integer'
  default_value: 0
  is_nullable: 0

=head2 mac

  data_type: 'macaddr'
  is_nullable: 1

=head2 cts

  data_type: 'timestamp without time zone'
  default_value: now()
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "usertrack_id",
  {
    data_type         => "integer",
    is_auto_increment => 1,
    is_nullable       => 0,
    sequence          => "usertrack_usertrack_id_seq",
  },
  "router_id",
  {
    data_type      => "integer",
    default_value  => 1,
    is_foreign_key => 1,
    is_nullable    => 0,
  },
  "totalkb",
  { data_type => "integer", default_value => 0, is_nullable => 0 },
  "hostname",
  { data_type => "text", default_value => "", is_nullable => 0 },
  "kbup",
  { data_type => "integer", default_value => 0, is_nullable => 0 },
  "kbdown",
  { data_type => "integer", default_value => 0, is_nullable => 0 },
  "kbtotal",
  { data_type => "integer", default_value => 0, is_nullable => 0 },
  "mac",
  { data_type => "macaddr", is_nullable => 1 },
  "cts",
  {
    data_type     => "timestamp without time zone",
    default_value => \"now()",
    is_nullable   => 1,
  },
);
__PACKAGE__->set_primary_key("usertrack_id");

=head1 RELATIONS

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
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:MD9eRVdpc8XK0IpVkyLyFA
# These lines were loaded from '/Users/phred/dev/perl-5.12.0/lib/site_perl/5.12.0/SL/Model/App/Usertrack.pm' found in @INC.
# They are now part of the custom portion of this file
# for you to hand-edit.  If you do not either delete
# this section or remove that file from @INC, this section
# will be repeated redundantly when you re-create this
# file again via Loader!  See skip_load_external to disable
# this feature.

package SL::Model::App::Usertrack;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("Core");
__PACKAGE__->table("usertrack");
__PACKAGE__->add_columns(
  "usertrack_id",
  {
    data_type => "integer",
    default_value => "nextval('usertrack_usertrack_id_seq'::regclass)",
    is_auto_increment => 1,
    is_nullable => 0,
    size => 4,
  },
  "router_id",
  {
    data_type => "integer",
    default_value => 1,
    is_foreign_key => 1,
    is_nullable => 0,
    size => 4,
  },
  "totalkb",
  { data_type => "integer", default_value => 0, is_nullable => 0, size => 4 },
  "hostname",
  {
    data_type => "text",
    default_value => "''::text",
    is_nullable => 0,
    size => undef,
  },
  "kbup",
  { data_type => "integer", default_value => 0, is_nullable => 0, size => 4 },
  "kbdown",
  { data_type => "integer", default_value => 0, is_nullable => 0, size => 4 },
  "mac",
  { data_type => "macaddr", default_value => undef, is_nullable => 1, size => 6 },
  "cts",
  {
    data_type => "timestamp without time zone",
    default_value => "now()",
    is_nullable => 1,
    size => 8,
  },
);
__PACKAGE__->set_primary_key("usertrack_id");
__PACKAGE__->belongs_to(
  "router",
  "SL::Model::App::Router",
  { router_id => "router_id" },
);


# Created by DBIx::Class::Schema::Loader v0.04999_08 @ 2009-09-01 15:52:24
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:eGlL0nR4DpbUUMBIeqatVg


# You can replace this text with custom content, and it will be preserved on regeneration
1;
# End of lines loaded from '/Users/phred/dev/perl-5.12.0/lib/site_perl/5.12.0/SL/Model/App/Usertrack.pm' 


# You can replace this text with custom content, and it will be preserved on regeneration
1;
