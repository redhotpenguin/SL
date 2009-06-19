package SL::Model::App::PaypalAttempt;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("InflateColumn::DateTime", "Core");
__PACKAGE__->table("paypal_attempt");
__PACKAGE__->add_columns(
  "paypal_attempt_id",
  {
    data_type => "integer",
    default_value => "nextval('paypal_attempt_paypal_attempt_id_seq'::regclass)",
    is_auto_increment => 1,
    is_nullable => 0,
    size => 4,
  },
  "account_id",
  {
    data_type => "integer",
    default_value => undef,
    is_foreign_key => 1,
    is_nullable => 0,
    size => 4,
  },
);
__PACKAGE__->set_primary_key("paypal_attempt_id");
__PACKAGE__->belongs_to(
  "account",
  "SL::Model::App::Account",
  { account_id => "account_id" },
);


# Created by DBIx::Class::Schema::Loader v0.04999_07 @ 2009-06-14 16:15:26
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:A0IojXYhETlPdFYnU1iDCA


# You can replace this text with custom content, and it will be preserved on regeneration
1;
