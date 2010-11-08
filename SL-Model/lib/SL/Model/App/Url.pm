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

  data_type: 'varchar'
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

  data_type: 'timestamp'
  default_value: current_timestamp
  is_nullable: 1
  original: {default_value => \"now()"}

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
  { data_type => "varchar", is_nullable => 1, size => 256 },
  "blacklisted",
  { data_type => "boolean", default_value => \"true", is_nullable => 1 },
  "reg_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "ts",
  {
    data_type     => "timestamp",
    default_value => \"current_timestamp",
    is_nullable   => 1,
    original      => { default_value => \"now()" },
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


# Created by DBIx::Class::Schema::Loader v0.07002 @ 2010-11-08 15:50:46
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:LVaphkzuTXwUqJi0dDkxgg
# These lines were loaded from '/Users/phred/dev/perl-5.12.2/lib/site_perl/5.12.2/SL/Model/App/Url.pm' found in @INC.


# End of lines loaded from '/Users/phred/dev/perl-5.12.2/lib/site_perl/5.12.2/SL/Model/App/Url.pm' 
1;
