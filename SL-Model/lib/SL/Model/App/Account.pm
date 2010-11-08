package SL::Model::App::Account;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';

__PACKAGE__->load_components("InflateColumn::DateTime");

=head1 NAME

SL::Model::App::Account

=cut

__PACKAGE__->table("account");

=head1 ACCESSORS

=head2 account_id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0
  sequence: 'account_account_id_seq'

=head2 name

  data_type: 'text'
  is_nullable: 0

=head2 premium

  data_type: 'boolean'
  default_value: true
  is_nullable: 0

=head2 close_box

  data_type: 'boolean'
  default_value: true
  is_nullable: 0

=head2 active

  data_type: 'boolean'
  default_value: true
  is_nullable: 0

=head2 aaa_email_cc

  data_type: 'text'
  is_nullable: 1

=head2 advertise_here

  data_type: 'text'
  default_value: 'http://www.silverliningnetworks.com/site/advertise_here.html?'
  is_nullable: 1

=head2 plan

  data_type: 'text'
  default_value: 'free'
  is_nullable: 0

=head2 aaa

  data_type: 'boolean'
  default_value: false
  is_nullable: 0

=head2 twitter_id

  data_type: 'text'
  default_value: 'slwifi'
  is_nullable: 0

=head2 text_message

  data_type: 'text'
  default_value: 'This is the default text message for the Silver Lining Text Message Bar'
  is_nullable: 0

=head2 zone_type

  data_type: 'text'
  default_value: 'banner_ad'
  is_nullable: 0

=head2 dnsone

  data_type: 'inet'
  is_nullable: 1

=head2 dnstwo

  data_type: 'inet'
  is_nullable: 1

=head2 map_center

  data_type: 'text'
  default_value: 94109
  is_nullable: 0

=head2 map_zoom

  data_type: 'integer'
  default_value: 20
  is_nullable: 0

=head2 users_today

  data_type: 'integer'
  default_value: 0
  is_nullable: 0

=head2 megabytes_today

  data_type: 'integer'
  default_value: 0
  is_nullable: 0

=head2 users_monthly

  data_type: 'integer'
  default_value: 0
  is_nullable: 0

=head2 megabytes_monthly

  data_type: 'integer'
  default_value: 0
  is_nullable: 0

=head2 beta

  data_type: 'boolean'
  default_value: false
  is_nullable: 0

=head2 google_ad_client

  data_type: 'text'
  default_value: 'pub-9104946517470276'
  is_nullable: 0

=head2 persistent

  data_type: 'boolean'
  default_value: true
  is_nullable: 1

=head2 swap

  data_type: 'boolean'
  default_value: true
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "account_id",
  {
    data_type         => "integer",
    is_auto_increment => 1,
    is_nullable       => 0,
    sequence          => "account_account_id_seq",
  },
  "name",
  { data_type => "text", is_nullable => 0 },
  "premium",
  { data_type => "boolean", default_value => \"true", is_nullable => 0 },
  "close_box",
  { data_type => "boolean", default_value => \"true", is_nullable => 0 },
  "active",
  { data_type => "boolean", default_value => \"true", is_nullable => 0 },
  "aaa_email_cc",
  { data_type => "text", is_nullable => 1 },
  "advertise_here",
  {
    data_type     => "text",
    default_value => "http://www.silverliningnetworks.com/site/advertise_here.html?",
    is_nullable   => 1,
  },
  "plan",
  { data_type => "text", default_value => "free", is_nullable => 0 },
  "aaa",
  { data_type => "boolean", default_value => \"false", is_nullable => 0 },
  "twitter_id",
  { data_type => "text", default_value => "slwifi", is_nullable => 0 },
  "text_message",
  {
    data_type     => "text",
    default_value => "This is the default text message for the Silver Lining Text Message Bar",
    is_nullable   => 0,
  },
  "zone_type",
  { data_type => "text", default_value => "banner_ad", is_nullable => 0 },
  "dnsone",
  { data_type => "inet", is_nullable => 1 },
  "dnstwo",
  { data_type => "inet", is_nullable => 1 },
  "map_center",
  { data_type => "text", default_value => 94109, is_nullable => 0 },
  "map_zoom",
  { data_type => "integer", default_value => 20, is_nullable => 0 },
  "users_today",
  { data_type => "integer", default_value => 0, is_nullable => 0 },
  "megabytes_today",
  { data_type => "integer", default_value => 0, is_nullable => 0 },
  "users_monthly",
  { data_type => "integer", default_value => 0, is_nullable => 0 },
  "megabytes_monthly",
  { data_type => "integer", default_value => 0, is_nullable => 0 },
  "beta",
  { data_type => "boolean", default_value => \"false", is_nullable => 0 },
  "google_ad_client",
  {
    data_type     => "text",
    default_value => "pub-9104946517470276",
    is_nullable   => 0,
  },
  "persistent",
  { data_type => "boolean", default_value => \"true", is_nullable => 1 },
  "swap",
  { data_type => "boolean", default_value => \"true", is_nullable => 1 },
);
__PACKAGE__->set_primary_key("account_id");

=head1 RELATIONS

=head2 ad_zones

Type: has_many

Related object: L<SL::Model::App::AdZone>

=cut

__PACKAGE__->has_many(
  "ad_zones",
  "SL::Model::App::AdZone",
  { "foreign.account_id" => "self.account_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 networks

Type: has_many

Related object: L<SL::Model::App::Network>

=cut

__PACKAGE__->has_many(
  "networks",
  "SL::Model::App::Network",
  { "foreign.account_id" => "self.account_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 payments

Type: has_many

Related object: L<SL::Model::App::Payment>

=cut

__PACKAGE__->has_many(
  "payments",
  "SL::Model::App::Payment",
  { "foreign.account_id" => "self.account_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 regs

Type: has_many

Related object: L<SL::Model::App::Reg>

=cut

__PACKAGE__->has_many(
  "regs",
  "SL::Model::App::Reg",
  { "foreign.account_id" => "self.account_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 routers

Type: has_many

Related object: L<SL::Model::App::Router>

=cut

__PACKAGE__->has_many(
  "routers",
  "SL::Model::App::Router",
  { "foreign.account_id" => "self.account_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);


# Created by DBIx::Class::Schema::Loader v0.06001 @ 2010-09-02 12:45:09
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:dmoXiWWekNhdexQ7q7MNGg
# These lines were loaded from '/Users/phred/dev/perl-5.12.0/lib/site_perl/5.12.0/SL/Model/App/Account.pm' found in @INC.
# They are now part of the custom portion of this file
# for you to hand-edit.  If you do not either delete
# this section or remove that file from @INC, this section
# will be repeated redundantly when you re-create this
# file again via Loader!  See skip_load_external to disable
# this feature.

use Config::SL ();
use File::Path  ();
use Digest::MD5 ();
use Geo::Distance ();

our $Config = Config::SL->new();

use constant DEBUG => $ENV{SL_DEBUG} || 0;
use constant VERBOSE_DEBUG => $ENV{SL_VERBOSE_DEBUG} || 0;

sub report_dir_base {
    my $self = shift;

    return $self->{report_dir_base} if $self->{report_dir_base};

    # make the directory to store the reporting data
    my $dir = join( '/', $Config->sl_data_root, $self->report_base );

    File::Path::mkpath($dir) unless ( -d $dir );

    $self->{report_dir_base} = $dir;
    return $dir;
}

sub report_base {
    my $self = shift;
    return join( '/', Digest::MD5::md5_hex( $self->name ), 'report' );
}


# centers the map!

sub center_the_map {
    my $self = shift;

    my @routers =
      grep { defined $_->lat && defined $_->lng && $_->active } $self->routers;

    # make a circle from all the points (yeah right)
    my $geo = Geo::Distance->new;
    my %dist = ( meters => 0, rtrone => '', rtrtwo => '' );
    foreach my $rtr (@routers) {

        foreach my $ot_rtr (@routers) {
            next if $ot_rtr->router_id == $rtr->router_id;

            my $distance = $geo->distance(
                'meter',
                $rtr->lat, $rtr->lng =>
                  $ot_rtr->lat,
                $ot_rtr->lng,
            );
            warn(
                sprintf(
                    "distance between router %s and %s is %s",
                    $rtr->name, $ot_rtr->name, $distance
                )
            ) if VERBOSE_DEBUG;

            # ouch weird code
            if ( abs($dist{meters}) < $distance ) {

                # new distance
                $dist{meters} = $distance;
                $dist{rtrone} = $rtr;
                $dist{rtrtwo} = $ot_rtr;
            }

        }
    }

    warn("setting zoom for distance " . abs($dist{meters})) if DEBUG;
    if ( abs($dist{meters}) < 200 ) {
        $self->map_zoom(20);
    } else {
        $self->map_zoom(18);
    }

    my $rtr    = $dist{rtrone};
    my $ot_rtr = $dist{rtrtwo};

    # now get the center of those two points
    my ( $clat, $clng ) =
      ( ( $ot_rtr->lat + $rtr->lat ) / 2, ( $ot_rtr->lng + $rtr->lng ) / 2 );
    warn("clat $clat, clng $clng") if DEBUG;
    $self->map_center("$clat, $clng");
    $self->update;

}


sub update_example_ad_zones {
    my $self = shift;

    $self->zone_type('banner_ad');
    $self->update;

    my $image_href =
      'http://s1.slwifi.com/images/ads/sln/advertise_leaderboard.png';
    my $link_href = 'http://www.silverliningnetworks.com/advertise_here';

    my $adhere = SL::Model::App->resultset('AdZone')->create(
        {
            account_id => $self->account_id,
            ad_size_id => 12,
            image_href => $image_href,
            link_href  => $link_href,
            code       => sprintf(
                '<a href="%s"><img src="%s"></a>',
                $link_href, $image_href
            ),
            weight     => 2,
            name       => 'Example Banner Ad',
            is_default => 't',
            reg_id     => 14,
        }
    );
    $adhere->update;

    my $bughere = SL::Model::App->resultset('AdZone')->create(
        {
            account_id => $self->account_id,
            ad_size_id => 22,
            image_href =>
'http://s1.slwifi.com/images/ads/sln/leaderboard_sponsored_by.gif',
            link_href =>
              'http://www.silverliningnetworks.com/?branding_account='
              . $self->account_id,
            code       => '',
            weight     => 2,
            name       => 'Example Branding Image',
            is_default => 't',
            reg_id     => 14,
        }
    );
    $bughere->update;

    my $splash = SL::Model::App->resultset('AdZone')->create(
        {
            account_id => $self->account_id,
            ad_size_id => 15,
            image_href => 'http://s1.slwifi.com/images/ads/sln/300x250.gif',
            link_href  => 'http://www.silverliningnetworks.com/?splash_account='
              . $self->account_id,
            code       => '',
            weight     => 2,
            name       => 'Example Splash Page Ad',
            is_default => 't',
            reg_id     => 14,
        }
    );
    $bughere->update;

    return 1;
}

sub get_ad_zones {
    my $self = shift;

    # ad zones allowed for this user
    my @ad_zones = SL::Model::App->resultset('AdZone')->search(
        {
            active     => 't',
            account_id => $self->account_id
        }
    );

    return unless scalar(@ad_zones) > 0;

    # get router count for each ad zone
    $self->process_ad_zone($_) for @ad_zones;

    return @ad_zones;
}

sub process_ad_zone {
    my ( $self, $ad_zone ) = @_;

    # get routers for this account
    my @routers =
      SL::Model::App->resultset('Router')
      ->search( { account_id => $self->account_id } );

    if ( scalar(@routers) == 0 ) {
        $ad_zone->{router_count} = 0;
        return 1;
    }

    # get the count of routers for this zone
    $ad_zone->{router_count} =
      SL::Model::App->resultset('RouterAdZone')->search(
        {
            ad_zone_id => $ad_zone->ad_zone_id,
            router_id  => { -in => [ map { $_->router_id } @routers ] }
        }
      )->count;

    return 1;
}

# same as views but just count
sub views_count {
    my ( $self, $start, $end, $routers_aryref ) = @_;
    die 'start and end invalid'
      unless SL::Model::App::validate_dt( $start, $end );
    die 'please specify routers' unless $routers_aryref;

    my $views_hashref;
    my $total = 0;
    foreach
      my $router ( sort { $a->router_id <=> $b->router_id } @{$routers_aryref} )
    {

        my $router_name =
             $router->name
          || $router->macaddr
          || sprintf( 'empty router id %d', $router->router_id );
        print "===> processing router $router_name\n" if DEBUG;
        my $count = $router->views_count( $start, $end );
        $total += $count;

        $views_hashref->{routers}->{ $router->router_id }->{count} = $count
          || 0;
    }
    $views_hashref->{total} = $total;

    return $views_hashref;
}

# number of users seen in a time period
sub users_count {
    my ( $self, $start, $end, $routers_aryref ) = @_;
    die 'start and end invalid'
      unless SL::Model::App::validate_dt( $start, $end );
    die 'please specify routers' unless $routers_aryref;

    my $users_hashref;
    my $total = 0;
    foreach
      my $router ( sort { $a->router_id <=> $b->router_id } @{$routers_aryref} )
    {

        my $router_name =
             $router->name
          || $router->macaddr
          || sprintf( 'empty router id %d', $router->router_id );

        print "===> processing router $router_name\n" if DEBUG;
        my $count = $router->users_count( $start, $end );
        $total += $count;

        $users_hashref->{routers}->{ $router->router_id }->{count} = $count
          || 0;
    }
    $users_hashref->{total} = $total;

    return $users_hashref;
}

sub users_unique {
    my ( $self, $start, $end, $routers_aryref ) = @_;
    my $users_hashref = $self->users_count( $start, $end, $routers_aryref );

    return $users_hashref->{total};
}

sub get_routers {
    my $self = shift;

    my @routers = SL::Model::App->resultset('Router')->search(
        {
            account_id => $self->account_id,
            active     => 't'
        },
        { -order_by => 'mts DESC' },
    );

    return unless scalar(@routers) > 0;

    return \@routers;
}

1;

# End of lines loaded from '/Users/phred/dev/perl/lib/site_perl/5.8.8/SL/Model/App/Account.pm' 
