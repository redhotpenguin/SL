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

  data_type: 'timestamp'
  default_value: current_timestamp
  is_nullable: 1
  original: {default_value => \"now()"}

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
    data_type     => "timestamp",
    default_value => \"current_timestamp",
    is_nullable   => 1,
    original      => { default_value => \"now()" },
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


# Created by DBIx::Class::Schema::Loader v0.07002 @ 2010-11-08 15:50:46
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:lrD/+KuRsvq4mfc/mu2pjA
# These lines were loaded from '/Users/phred/dev/perl-5.12.2/lib/site_perl/5.12.2/SL/Model/App/Usertrack.pm' found in @INC.

1;
