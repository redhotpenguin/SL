package SL::Model::App::Reg;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("Core");
__PACKAGE__->table("reg");
__PACKAGE__->add_columns(
  "reg_id",
  {
    data_type => "integer",
    default_value => "nextval('reg_reg_id_seq'::regclass)",
    is_nullable => 0,
    size => 4,
  },
  "email",
  {
    data_type => "character varying",
    default_value => "''::character varying",
    is_nullable => 0,
    size => 64,
  },
  "mts",
  {
    data_type => "timestamp without time zone",
    default_value => "now()",
    is_nullable => 1,
    size => 8,
  },
  "active",
  {
    data_type => "boolean",
    default_value => "true",
    is_nullable => 1,
    size => 1,
  },
  "report_email",
  {
    data_type => "character varying",
    default_value => "''::character varying",
    is_nullable => 1,
    size => 64,
  },
  "password_md5",
  {
    data_type => "character varying",
    default_value => undef,
    is_nullable => 1,
    size => 32,
  },
  "send_reports_daily",
  {
    data_type => "boolean",
    default_value => "false",
    is_nullable => 1,
    size => 1,
  },
  "send_reports_weekly",
  {
    data_type => "boolean",
    default_value => "false",
    is_nullable => 1,
    size => 1,
  },
  "send_reports_monthly",
  {
    data_type => "boolean",
    default_value => "false",
    is_nullable => 1,
    size => 1,
  },
  "send_reports_quarterly",
  {
    data_type => "boolean",
    default_value => "false",
    is_nullable => 1,
    size => 1,
  },
  "report_email_frequency",
  {
    data_type => "character varying",
    default_value => "''::character varying",
    is_nullable => 0,
    size => 16,
  },
  "account_id",
  { data_type => "integer", default_value => 1, is_nullable => 0, size => 4 },
  "admin",
  {
    data_type => "boolean",
    default_value => "true",
    is_nullable => 0,
    size => 1,
  },
  "first_name",
  {
    data_type => "text",
    default_value => "''::text",
    is_nullable => 0,
    size => undef,
  },
  "last_name",
  {
    data_type => "text",
    default_value => "''::text",
    is_nullable => 0,
    size => undef,
  },
);
__PACKAGE__->set_primary_key("reg_id");
__PACKAGE__->add_unique_constraint("reg_id_pkey", ["reg_id"]);
__PACKAGE__->has_many(
  "ad_zones",
  "SL::Model::App::AdZone",
  { "foreign.reg_id" => "self.reg_id" },
);
__PACKAGE__->has_many(
  "forgots",
  "SL::Model::App::Forgot",
  { "foreign.reg_id" => "self.reg_id" },
);
__PACKAGE__->belongs_to(
  "account_id",
  "SL::Model::App::Account",
  { account_id => "account_id" },
);
__PACKAGE__->has_many(
  "urls",
  "SL::Model::App::Url",
  { "foreign.reg_id" => "self.reg_id" },
);


# Created by DBIx::Class::Schema::Loader v0.04002 @ 2008-05-27 12:35:20
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:dLewfI+AHp21rBSj7zc6UA

# These lines were loaded from '/Users/phred/dev/perl/lib/site_perl/5.8.8/SL/Model/App/Reg.pm' found in @INC.# They are now part of the custom portion of this file# for you to hand-edit.  If you do not either delete# this section or remove that file from @INC, this section# will be repeated redundantly when you re-create this# file again via Loader!

use Digest::MD5      ();
use File::Path       ();
use SL::Model::App   ();
use SL::Config       ();

our $config = SL::Config->new();

use constant DEBUG => $ENV{SL_DEBUG} || 0;
require Data::Dumper if DEBUG;

sub report_dir_base {
    my $self = shift;

    return $self->{report_dir_base} if $self->{report_dir_base};

    # make the directory to store the reporting data
     my $dir = join ( '/', $config->sl_data_root, $self->report_base );

    File::Path::mkpath($dir) unless ( -d $dir );

    $self->{report_dir_base} = $dir;
    return $dir;
}

sub report_base {
  my $self = shift;
  return join('/', Digest::MD5::md5_hex( $self->account_id->name ), 'report');
}

sub get_ad_zone {
    my ( $self, $ad_zone_id ) = @_;

    my ($ad_zone) =
      SL::Model::App->resultset('AdZone')
      ->search( { ad_zone_id => $ad_zone_id,
                  account_id => $self->account_id->account_id } );

    return unless $ad_zone;

    $self->process_ad_zone($ad_zone);

    return $ad_zone;
}

sub get_ad_zones {
    my $self = shift;

    # ad zones allowed for this user
    my @ad_zones = SL::Model::App->resultset('AdZone')->search({
                     account_id => $self->account_id->account_id });

    return unless scalar(@ad_zones) > 0;

    # get router count for each ad zone
    $self->process_ad_zone($_) for @ad_zones;

    return @ad_zones;
}

sub process_ad_zone {
    my ( $self, $ad_zone ) = @_;

    # get routers for this account
    my @routers = SL::Model::App->resultset('Router')->search({
             account_id => $self->account_id->account_id });

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

    $router->{location_count} = $router->router__locations->count;
    $router->{ad_zone_count} = $router->router__ad_zones->count;

    return 1;
}

sub get_routers {
    my ( $self, $ad_zone_id ) = @_;

    my @routers = SL::Model::App->resultset('Router')->search({
        account_id => $self->account_id->account_id });

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

# same as views but just count
sub views_count {
    my ( $self, $start, $end, $routers_aryref ) = @_;
    die 'start and end invalid'
      unless SL::Model::App::validate_dt( $start, $end );
    die 'please specify routers' unless $routers_aryref;

    my $views_hashref;
    my $total = 0;
    foreach my $router ( sort { $a->router_id <=> $b->router_id }
                         @{$routers_aryref} ) {
        my $count = $router->views_count( $start, $end );
        $total += $count;

        $views_hashref->{routers}->{ $router->router_id }->{count} =
          $count || 0;
    }
    $views_hashref->{total} = $total;

    return $views_hashref;
}

1;

