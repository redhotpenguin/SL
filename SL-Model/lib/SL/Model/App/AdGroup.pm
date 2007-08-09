package SL::Model::App::AdGroup;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("Core");
__PACKAGE__->table("ad_group");
__PACKAGE__->add_columns(
  "ad_group_id",
  {
    data_type => "integer",
    default_value => "nextval('ad_group_ad_group_id_seq'::regclass)",
    is_nullable => 0,
    size => 4,
  },
  "active",
  {
    data_type => "boolean",
    default_value => "true",
    is_nullable => 1,
    size => 1,
  },
  "name",
  {
    data_type => "character varying",
    default_value => undef,
    is_nullable => 1,
    size => 256,
  },
  "cts",
  {
    data_type => "timestamp without time zone",
    default_value => "now()",
    is_nullable => 1,
    size => 8,
  },
  "css_url",
  {
    data_type => "text",
    default_value => "'http://www.redhotpenguin.com/css/sl.css'::text",
    is_nullable => 0,
    size => undef,
  },
  "template",
  {
    data_type => "text",
    default_value => "'text_ad.tmpl'::text",
    is_nullable => 0,
    size => undef,
  },
  "bug_id",
  { data_type => "integer", default_value => 1, is_nullable => 0, size => 4 },
  "is_default",
  {
    data_type => "boolean",
    default_value => "false",
    is_nullable => 1,
    size => 1,
  },
  "reg_id",
  { data_type => "integer", default_value => 14, is_nullable => 0, size => 4 },
);
__PACKAGE__->set_primary_key("ad_group_id");
__PACKAGE__->has_many(
  "ads",
  "SL::Model::App::Ad",
  { "foreign.ad_group_id" => "self.ad_group_id" },
);
__PACKAGE__->belongs_to("reg_id", "SL::Model::App::Reg", { reg_id => "reg_id" });
__PACKAGE__->belongs_to("bug_id", "SL::Model::App::Bug", { bug_id => "bug_id" });
__PACKAGE__->has_many(
  "location__ad_groups",
  "SL::Model::App::LocationAdGroup",
  { "foreign.ad_group_id" => "self.ad_group_id" },
);
__PACKAGE__->has_many(
  "reg__ad_groups",
  "SL::Model::App::RegAdGroup",
  { "foreign.ad_group_id" => "self.ad_group_id" },
);

sub get_ad_sls {
  my $self = shift;

  my @ad_ids = map { $_->ad_id } $self->ads;
  return unless (scalar(@ad_ids) > 0 );

  my @ad_sls = SL::Model::App->resultset('AdSl')->search({
           ad_id => { -in => \@ad_ids } });

  return unless (scalar(@ad_sls) > 0);

  return wantarray ? @ad_sls : \@ad_sls;

}

1;
