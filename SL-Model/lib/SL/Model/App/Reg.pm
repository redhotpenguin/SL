package SL::Model::App::Reg;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';

__PACKAGE__->load_components("InflateColumn::DateTime");

=head1 NAME

SL::Model::App::Reg

=cut

__PACKAGE__->table("reg");

=head1 ACCESSORS

=head2 reg_id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0
  sequence: 'reg_reg_id_seq'

=head2 email

  data_type: 'varchar'
  default_value: (empty string)
  is_nullable: 0
  size: 64

=head2 mts

  data_type: 'timestamp'
  default_value: current_timestamp
  is_nullable: 1
  original: {default_value => \"now()"}

=head2 city

  data_type: 'varchar'
  is_nullable: 1
  size: 64

=head2 state

  data_type: 'char'
  is_nullable: 1
  size: 2

=head2 active

  data_type: 'boolean'
  default_value: true
  is_nullable: 1

=head2 report_email

  data_type: 'varchar'
  default_value: (empty string)
  is_nullable: 1
  size: 64

=head2 password_md5

  data_type: 'varchar'
  is_nullable: 1
  size: 32

=head2 send_reports_daily

  data_type: 'boolean'
  default_value: false
  is_nullable: 1

=head2 send_reports_weekly

  data_type: 'boolean'
  default_value: false
  is_nullable: 1

=head2 send_reports_monthly

  data_type: 'boolean'
  default_value: false
  is_nullable: 1

=head2 send_reports_quarterly

  data_type: 'boolean'
  default_value: false
  is_nullable: 1

=head2 report_email_frequency

  data_type: 'varchar'
  default_value: (empty string)
  is_nullable: 0
  size: 16

=head2 account_id

  data_type: 'integer'
  default_value: 1
  is_foreign_key: 1
  is_nullable: 0

=head2 root

  data_type: 'boolean'
  default_value: false
  is_nullable: 0

=head2 paypal_id

  data_type: 'text'
  is_nullable: 1

=head2 first_name

  data_type: 'text'
  default_value: (empty string)
  is_nullable: 0

=head2 last_name

  data_type: 'text'
  default_value: (empty string)
  is_nullable: 0

=head2 street

  data_type: 'text'
  default_value: (empty string)
  is_nullable: 0

=head2 zip

  data_type: 'text'
  default_value: (empty string)
  is_nullable: 0

=head2 card_last_four

  data_type: 'text'
  default_value: (empty string)
  is_nullable: 0

=head2 card_type

  data_type: 'text'
  default_value: (empty string)
  is_nullable: 0

=head2 card_expires

  data_type: 'text'
  default_value: (empty string)
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "reg_id",
  {
    data_type         => "integer",
    is_auto_increment => 1,
    is_nullable       => 0,
    sequence          => "reg_reg_id_seq",
  },
  "email",
  { data_type => "varchar", default_value => "", is_nullable => 0, size => 64 },
  "mts",
  {
    data_type     => "timestamp",
    default_value => \"current_timestamp",
    is_nullable   => 1,
    original      => { default_value => \"now()" },
  },
  "city",
  { data_type => "varchar", is_nullable => 1, size => 64 },
  "state",
  { data_type => "char", is_nullable => 1, size => 2 },
  "active",
  { data_type => "boolean", default_value => \"true", is_nullable => 1 },
  "report_email",
  { data_type => "varchar", default_value => "", is_nullable => 1, size => 64 },
  "password_md5",
  { data_type => "varchar", is_nullable => 1, size => 32 },
  "send_reports_daily",
  { data_type => "boolean", default_value => \"false", is_nullable => 1 },
  "send_reports_weekly",
  { data_type => "boolean", default_value => \"false", is_nullable => 1 },
  "send_reports_monthly",
  { data_type => "boolean", default_value => \"false", is_nullable => 1 },
  "send_reports_quarterly",
  { data_type => "boolean", default_value => \"false", is_nullable => 1 },
  "report_email_frequency",
  { data_type => "varchar", default_value => "", is_nullable => 0, size => 16 },
  "account_id",
  {
    data_type      => "integer",
    default_value  => 1,
    is_foreign_key => 1,
    is_nullable    => 0,
  },
  "root",
  { data_type => "boolean", default_value => \"false", is_nullable => 0 },
  "paypal_id",
  { data_type => "text", is_nullable => 1 },
  "first_name",
  { data_type => "text", default_value => "", is_nullable => 0 },
  "last_name",
  { data_type => "text", default_value => "", is_nullable => 0 },
  "street",
  { data_type => "text", default_value => "", is_nullable => 0 },
  "zip",
  { data_type => "text", default_value => "", is_nullable => 0 },
  "card_last_four",
  { data_type => "text", default_value => "", is_nullable => 0 },
  "card_type",
  { data_type => "text", default_value => "", is_nullable => 0 },
  "card_expires",
  { data_type => "text", default_value => "", is_nullable => 0 },
);
__PACKAGE__->set_primary_key("reg_id");

=head1 RELATIONS

=head2 ad_zones

Type: has_many

Related object: L<SL::Model::App::AdZone>

=cut

__PACKAGE__->has_many(
  "ad_zones",
  "SL::Model::App::AdZone",
  { "foreign.reg_id" => "self.reg_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 forgots

Type: has_many

Related object: L<SL::Model::App::Forgot>

=cut

__PACKAGE__->has_many(
  "forgots",
  "SL::Model::App::Forgot",
  { "foreign.reg_id" => "self.reg_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 account

Type: belongs_to

Related object: L<SL::Model::App::Account>

=cut

__PACKAGE__->belongs_to(
  "account",
  "SL::Model::App::Account",
  { account_id => "account_id" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "CASCADE" },
);

=head2 urls

Type: has_many

Related object: L<SL::Model::App::Url>

=cut

__PACKAGE__->has_many(
  "urls",
  "SL::Model::App::Url",
  { "foreign.reg_id" => "self.reg_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);


# Created by DBIx::Class::Schema::Loader v0.07002 @ 2010-11-08 15:50:46
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:wjcx/x8WOHSbIMgPEm7OCQ
# These lines were loaded from '/Users/phred/dev/perl-5.12.2/lib/site_perl/5.12.2/SL/Model/App/Reg.pm' found in @INC.

use Config::SL ();

our $config = Config::SL->new();

sub get_twitter_zone {
  my $self = shift;

  my ($ad_zone) =
    SL::Model::App->resultset('AdZone')->search({
                account_id => $self->account_id,
                name => '_twitter_feed',
                ad_size_id => 23,
                active => 1,
                hidden => 1, });

    return unless $ad_zone;

    $self->process_ad_zone($ad_zone);

    return $ad_zone;
}

sub get_msg_zone {
  my $self = shift;

  my ($ad_zone) =
    SL::Model::App->resultset('AdZone')->search({
                account_id => $self->account_id,
                name => '_message_bar',
                ad_size_id => 23,
                active => 1,
                hidden => 1, });

    return unless $ad_zone;

    $self->process_ad_zone($ad_zone);

    return $ad_zone;
}

sub get_ad_zone {
    my ( $self, $ad_zone_id ) = @_;

    my ($ad_zone) =
      SL::Model::App->resultset('AdZone')
      ->search( { ad_zone_id => $ad_zone_id, });

	if (!$ad_zone->public) {
		return unless
			$self->account->account_id == $ad_zone->account->account_id;
	}

    $self->process_ad_zone($ad_zone);

    return $ad_zone;
}

sub get_ad_zones {
    my $self = shift;

    # ad zones allowed for this user
    my @ad_zones = SL::Model::App->resultset('AdZone')->search({
					 active => 't',
                     account_id => $self->account->account_id });

    return unless scalar(@ad_zones) > 0;

    # get router count for each ad zone
    $self->process_ad_zone($_) for @ad_zones;

    return @ad_zones;
}

sub get_persistent_zones {
    my $self = shift;

    my @ad_sizes = $self->get_persistent_sizes;

    # ad zones allowed for this user
    my @ad_zones = SL::Model::App->resultset('AdZone')->search({
					 active => 't',
                     account_id => $self->account->account_id,
                     ad_size_id => { -in => [ qw( 1 10 12  ) ] }, });

    return unless scalar(@ad_zones) > 0;

    # get router count for each ad zone
    $self->process_ad_zone($_) for @ad_zones;

    return @ad_zones;
}


sub get_persistent_sizes {
    my $self = shift;

    my @ad_sizes = SL::Model::App->resultset('AdSize')->search({
                     persistent => 't',
                     grouping => [ 1,6,8 ],
                     hidden => 0,},);

    return unless scalar(@ad_sizes) > 0;

    return @ad_sizes;
}


sub get_swap_zones {
    my $self = shift;

    my $ad_sizes = $self->get_swap_sizes;

    my @ad_size_ids = map { $_->ad_size_id } @{$ad_sizes};

    # ad zones allowed for this user
    my @ad_zones = SL::Model::App->resultset('AdZone')->search({
					 active => 't',
                     account_id => $self->account->account_id,
                     ad_size_id => { -in => \@ad_size_ids }});

    return unless scalar(@ad_zones) > 0;

    # filter out internal zones
    @ad_zones = grep { ($_->name ne '_twitter_bug')
                         and ($_->name ne '_msg_bug') } @ad_zones;


    # get router count for each ad zone
    $self->process_ad_zone($_) for @ad_zones;

    return @ad_zones;
}

sub get_swap_sizes {

  my @ad_sizes = SL::Model::App->resultset('AdSize')->search({
        swap => 1, });

  return  [ sort { $a->grouping <=> $b->grouping  } @ad_sizes ];
}

sub get_splash_zones {
    my $self = shift;

    my @ad_sizes = $self->get_splash_sizes;

    # ad zones allowed for this user
    my @ad_zones = SL::Model::App->resultset('AdZone')->search({
					 active => 't',
                     account_id => $self->account->account_id,
                     ad_size_id => { -in => [ map { $_->ad_size_id }
                                          @ad_sizes  ], },});

    return unless scalar(@ad_zones) > 0;

    # get router count for each ad zone
    $self->process_ad_zone($_) for @ad_zones;

    return @ad_zones;
}


sub get_splash_sizes {
    my $self = shift;

    my @ad_sizes = SL::Model::App->resultset('AdSize')->search({
                     ad_size_id => 15,});

    return unless scalar(@ad_sizes) > 0;

    return @ad_sizes;
}





sub get_branding_zones {
    my $self = shift;

    my @ad_sizes = $self->get_branding_sizes;

    # ad zones allowed for this user
    my @ad_zones = SL::Model::App->resultset('AdZone')->search({
					 active => 't',
                     account_id => $self->account->account_id,
                     ad_size_id => { -in => [20,22], },});

    return unless scalar(@ad_zones) > 0;

    # get router count for each ad zone
    $self->process_ad_zone($_) for @ad_zones;

    return @ad_zones;
}



sub get_branding_sizes {
    my $self = shift;

    my @ad_sizes = SL::Model::App->resultset('AdSize')->search({
                     ad_size_id => { -in => [20,22], }, });

    return unless scalar(@ad_sizes) > 0;

    return @ad_sizes;
}





sub process_ad_zone {
    my ( $self, $ad_zone ) = @_;

    # get routers for this account
    my @routers = SL::Model::App->resultset('Router')->search({
             account_id => $self->account->account_id });

    if ( scalar(@routers) == 0 ) {
        $ad_zone->{router_count} = 0;
        return 1;
    }

    # get the count of routers for this zone
    $ad_zone->{router_count} =
      SL::Model::App->resultset('RouterAdZone')->search(
        {
            ad_zone_id => $ad_zone->ad_zone_id,
            router_id   => { -in => [ map { $_->router_id } @routers ] }
        }
      )->count;

    return 1;
}

sub process_router {
    my ( $self, $router ) = @_;

    $router->{ad_zone_count} = $router->router__ad_zones->count;

    return 1;
}

sub get_routers {
    my ( $self, $ad_zone_id ) = @_;

    my $account = $self->account;
    my $devices = $account->get_routers;

    return unless defined $devices;

    my @routers = @{$devices};
    return unless scalar(@routers) > 0;

    # add metadata
    $self->process_router($_) for @routers;
    return @routers unless $ad_zone_id;

    # filter the routers which have this ad zone
	my %router_hash = map { $_->router_id => $_ } @routers;

	my @filtered_routers;
	foreach my $router_id ( keys %router_hash ) {
		if (my ($exists) = SL::Model::App->resultset('RouterAdZone')->search(
				{
					ad_zone_id => $ad_zone_id,
					router_id   => $router_id, })) {
				push @filtered_routers, $router_hash{$router_id};
			}
	}


    return unless scalar(@filtered_routers) > 0;
    $self->process_router($_) for @filtered_routers;
    return @filtered_routers;
}

1;
