package SL::Model::App::Router;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';

__PACKAGE__->load_components("InflateColumn::DateTime");

=head1 NAME

SL::Model::App::Router

=cut

__PACKAGE__->table("router");

=head1 ACCESSORS

=head2 router_id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0
  sequence: 'router_router_id_seq'

=head2 serial_number

  data_type: 'varchar'
  is_nullable: 1
  size: 24

=head2 macaddr

  data_type: 'macaddr'
  is_nullable: 1

=head2 cts

  data_type: 'timestamp'
  default_value: current_timestamp
  is_nullable: 1
  original: {default_value => \"now()"}

=head2 mts

  data_type: 'timestamp'
  default_value: current_timestamp
  is_nullable: 1
  original: {default_value => \"now()"}

=head2 active

  data_type: 'boolean'
  default_value: true
  is_nullable: 1

=head2 proxy

  data_type: 'inet'
  is_nullable: 1

=head2 description

  data_type: 'text'
  is_nullable: 1

=head2 name

  data_type: 'text'
  is_nullable: 1

=head2 splash_timeout

  data_type: 'integer'
  default_value: 60
  is_nullable: 1

=head2 splash_href

  data_type: 'text'
  default_value: (empty string)
  is_nullable: 1

=head2 firmware_version

  data_type: 'text'
  default_value: (empty string)
  is_nullable: 1

=head2 ssid

  data_type: 'text'
  default_value: (empty string)
  is_nullable: 1

=head2 passwd_event

  data_type: 'text'
  default_value: (empty string)
  is_nullable: 1

=head2 firmware_event

  data_type: 'text'
  default_value: (empty string)
  is_nullable: 1

=head2 ssid_event

  data_type: 'text'
  default_value: (empty string)
  is_nullable: 1

=head2 reboot_event

  data_type: 'text'
  default_value: (empty string)
  is_nullable: 1

=head2 halt_event

  data_type: 'text'
  default_value: (empty string)
  is_nullable: 1

=head2 last_ping

  data_type: 'timestamp'
  default_value: current_timestamp
  is_nullable: 1
  original: {default_value => \"now()"}

=head2 views_daily

  data_type: 'integer'
  default_value: 0
  is_nullable: 0

=head2 account_id

  data_type: 'integer'
  default_value: 1
  is_foreign_key: 1
  is_nullable: 0

=head2 wan_ip

  data_type: 'inet'
  is_nullable: 1

=head2 lan_ip

  data_type: 'inet'
  is_nullable: 1

=head2 show_aaa_link

  data_type: 'boolean'
  default_value: false
  is_nullable: 0

=head2 device

  data_type: 'varchar'
  default_value: (empty string)
  is_nullable: 1
  size: 64

=head2 adserving

  data_type: 'boolean'
  default_value: false
  is_nullable: 0

=head2 notes

  data_type: 'text'
  default_value: (empty string)
  is_nullable: 0

=head2 lat

  data_type: 'double precision'
  is_nullable: 1

=head2 lng

  data_type: 'double precision'
  is_nullable: 1

=head2 ip

  data_type: 'inet'
  is_nullable: 1

=head2 users_daily

  data_type: 'integer'
  default_value: 0
  is_nullable: 0

=head2 traffic_daily

  data_type: 'integer'
  default_value: 0
  is_nullable: 0

=head2 memfree

  data_type: 'integer'
  default_value: 0
  is_nullable: 0

=head2 clients

  data_type: 'integer'
  default_value: 0
  is_nullable: 0

=head2 hops

  data_type: 'integer'
  default_value: 0
  is_nullable: 0

=head2 kbup

  data_type: 'integer'
  default_value: 0
  is_nullable: 0

=head2 kbdown

  data_type: 'integer'
  default_value: 0
  is_nullable: 0

=head2 neighbors

  data_type: 'text'
  default_value: (empty string)
  is_nullable: 0

=head2 gateway_quality

  data_type: 'text'
  default_value: (empty string)
  is_nullable: 0

=head2 routes

  data_type: 'text'
  default_value: (empty string)
  is_nullable: 0

=head2 load

  data_type: 'text'
  default_value: (empty string)
  is_nullable: 0

=head2 download_last

  data_type: 'integer'
  default_value: 0
  is_nullable: 0

=head2 download_average

  data_type: 'integer'
  default_value: 0
  is_nullable: 0

=head2 mesh_ip

  data_type: 'inet'
  is_nullable: 1

=head2 checkin_status

  data_type: 'text'
  default_value: 'No checkin history'
  is_nullable: 0

=head2 speed_test

  data_type: 'text'
  default_value: 'No speed test data'
  is_nullable: 0

=head2 firmware_build

  data_type: 'text'
  default_value: (empty string)
  is_nullable: 0

=head2 users_monthly

  data_type: 'integer'
  default_value: 0
  is_nullable: 0

=head2 megabytes_monthly

  data_type: 'integer'
  default_value: 0
  is_nullable: 0

=head2 gateway

  data_type: 'inet'
  is_nullable: 1

=head2 robin

  data_type: 'text'
  default_value: (empty string)
  is_nullable: 0

=head2 default_skips

  data_type: 'text'
  default_value: (empty string)
  is_nullable: 0

=head2 custom_skips

  data_type: 'text'
  default_value: (empty string)
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "router_id",
  {
    data_type         => "integer",
    is_auto_increment => 1,
    is_nullable       => 0,
    sequence          => "router_router_id_seq",
  },
  "serial_number",
  { data_type => "varchar", is_nullable => 1, size => 24 },
  "macaddr",
  { data_type => "macaddr", is_nullable => 1 },
  "cts",
  {
    data_type     => "timestamp",
    default_value => \"current_timestamp",
    is_nullable   => 1,
    original      => { default_value => \"now()" },
  },
  "mts",
  {
    data_type     => "timestamp",
    default_value => \"current_timestamp",
    is_nullable   => 1,
    original      => { default_value => \"now()" },
  },
  "active",
  { data_type => "boolean", default_value => \"true", is_nullable => 1 },
  "proxy",
  { data_type => "inet", is_nullable => 1 },
  "description",
  { data_type => "text", is_nullable => 1 },
  "name",
  { data_type => "text", is_nullable => 1 },
  "splash_timeout",
  { data_type => "integer", default_value => 60, is_nullable => 1 },
  "splash_href",
  { data_type => "text", default_value => "", is_nullable => 1 },
  "firmware_version",
  { data_type => "text", default_value => "", is_nullable => 1 },
  "ssid",
  { data_type => "text", default_value => "", is_nullable => 1 },
  "passwd_event",
  { data_type => "text", default_value => "", is_nullable => 1 },
  "firmware_event",
  { data_type => "text", default_value => "", is_nullable => 1 },
  "ssid_event",
  { data_type => "text", default_value => "", is_nullable => 1 },
  "reboot_event",
  { data_type => "text", default_value => "", is_nullable => 1 },
  "halt_event",
  { data_type => "text", default_value => "", is_nullable => 1 },
  "last_ping",
  {
    data_type     => "timestamp",
    default_value => \"current_timestamp",
    is_nullable   => 1,
    original      => { default_value => \"now()" },
  },
  "views_daily",
  { data_type => "integer", default_value => 0, is_nullable => 0 },
  "account_id",
  {
    data_type      => "integer",
    default_value  => 1,
    is_foreign_key => 1,
    is_nullable    => 0,
  },
  "wan_ip",
  { data_type => "inet", is_nullable => 1 },
  "lan_ip",
  { data_type => "inet", is_nullable => 1 },
  "show_aaa_link",
  { data_type => "boolean", default_value => \"false", is_nullable => 0 },
  "device",
  { data_type => "varchar", default_value => "", is_nullable => 1, size => 64 },
  "adserving",
  { data_type => "boolean", default_value => \"false", is_nullable => 0 },
  "notes",
  { data_type => "text", default_value => "", is_nullable => 0 },
  "lat",
  { data_type => "double precision", is_nullable => 1 },
  "lng",
  { data_type => "double precision", is_nullable => 1 },
  "ip",
  { data_type => "inet", is_nullable => 1 },
  "users_daily",
  { data_type => "integer", default_value => 0, is_nullable => 0 },
  "traffic_daily",
  { data_type => "integer", default_value => 0, is_nullable => 0 },
  "memfree",
  { data_type => "integer", default_value => 0, is_nullable => 0 },
  "clients",
  { data_type => "integer", default_value => 0, is_nullable => 0 },
  "hops",
  { data_type => "integer", default_value => 0, is_nullable => 0 },
  "kbup",
  { data_type => "integer", default_value => 0, is_nullable => 0 },
  "kbdown",
  { data_type => "integer", default_value => 0, is_nullable => 0 },
  "neighbors",
  { data_type => "text", default_value => "", is_nullable => 0 },
  "gateway_quality",
  { data_type => "text", default_value => "", is_nullable => 0 },
  "routes",
  { data_type => "text", default_value => "", is_nullable => 0 },
  "load",
  { data_type => "text", default_value => "", is_nullable => 0 },
  "download_last",
  { data_type => "integer", default_value => 0, is_nullable => 0 },
  "download_average",
  { data_type => "integer", default_value => 0, is_nullable => 0 },
  "mesh_ip",
  { data_type => "inet", is_nullable => 1 },
  "checkin_status",
  {
    data_type     => "text",
    default_value => "No checkin history",
    is_nullable   => 0,
  },
  "speed_test",
  {
    data_type     => "text",
    default_value => "No speed test data",
    is_nullable   => 0,
  },
  "firmware_build",
  { data_type => "text", default_value => "", is_nullable => 0 },
  "users_monthly",
  { data_type => "integer", default_value => 0, is_nullable => 0 },
  "megabytes_monthly",
  { data_type => "integer", default_value => 0, is_nullable => 0 },
  "gateway",
  { data_type => "inet", is_nullable => 1 },
  "robin",
  { data_type => "text", default_value => "", is_nullable => 0 },
  "default_skips",
  { data_type => "text", default_value => "", is_nullable => 0 },
  "custom_skips",
  { data_type => "text", default_value => "", is_nullable => 0 },
);
__PACKAGE__->set_primary_key("router_id");
__PACKAGE__->add_unique_constraint("madaddr_uniq", ["macaddr"]);

=head1 RELATIONS

=head2 checkins

Type: has_many

Related object: L<SL::Model::App::Checkin>

=cut

__PACKAGE__->has_many(
  "checkins",
  "SL::Model::App::Checkin",
  { "foreign.router_id" => "self.router_id" },
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

=head2 router_ad_zones

Type: has_many

Related object: L<SL::Model::App::RouterAdZone>

=cut

__PACKAGE__->has_many(
  "router_ad_zones",
  "SL::Model::App::RouterAdZone",
  { "foreign.router_id" => "self.router_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 usertracks

Type: has_many

Related object: L<SL::Model::App::Usertrack>

=cut

__PACKAGE__->has_many(
  "usertracks",
  "SL::Model::App::Usertrack",
  { "foreign.router_id" => "self.router_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 views

Type: has_many

Related object: L<SL::Model::App::View>

=cut

__PACKAGE__->has_many(
  "views",
  "SL::Model::App::View",
  { "foreign.router_id" => "self.router_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);


# Created by DBIx::Class::Schema::Loader v0.07002 @ 2010-11-08 15:50:46
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:qNd/UAxhb9SsBc28R0Y6EQ

use DateTime::Format::Pg;

sub run_query {
    my ( $self, $sql, $start, $end) = @_;

    die unless $sql && $start && $end;

    unless ( $start->isa('DateTime') && $end->isa('DateTime') ) {
        croak('No start and end times passed!');
    }
    my $dbh = SL::Model->db_Main();
    my $sth = $dbh->prepare_cached($sql);

    $sth->bind_param( 1, DateTime::Format::Pg->format_datetime($start) );
    $sth->bind_param( 2, DateTime::Format::Pg->format_datetime($end) );
    $sth->bind_param( 3, $self->router_id );
    my $rv      = $sth->execute;
    my $ary_ref = $sth->fetchall_arrayref;
    return $ary_ref;
}

our $views_sql = <<SQL;
SELECT ad_zone_id, count(view_id)
FROM view
WHERE view.cts BETWEEN ? AND ?
AND router_id = ?
GROUP BY ad_zone_id
SQL


# @views = (
#         { ad_zone => $ad_zone_one_obj, count => '5' },
#         { ad_zone => $ad_zone_two_obj, count => '3' }, );

sub ad_views {
    my ( $self, $start, $end) = @_;
    die unless SL::Model::App::validate_dt( $start, $end );

    my $ary_ref = $self->run_query( $views_sql, $start, $end, $self->router_id );
    my @views;

    foreach my $ary ( @{$ary_ref} ) {
        my ($ad_zone) =
          SL::Model::App->resultset('AdZone')->search( { ad_zone_id => $ary->[0] } );
        push @views, { ad_zone => $ad_zone, count => $ary->[1] };
    }

    my $count = 0;
    foreach my $view (@views) {
        $count += $view->{count};
    }

    return ( $count, \@views );
}

sub board {
    my $self = shift;

    my $board;

    if ($self->device eq 'mr3201a') {

      my $mac = $self->macaddr;

      if (lc(substr($mac, 0, 8)) eq '00:18:0a') {

        $board = 'Meraki';

      } elsif (lc(substr($mac, 0, 8)) eq '00:19:3b') {

        $board = 'Williboard';

      } elsif (lc(substr($mac, 0, 8)) eq '00:18:84') {

        $board = 'Fon';

      } elsif (lc(substr($mac, 0, 8)) eq '00:02:6f') {

        $board = 'Engenius';

      } elsif (lc(substr($mac, 0, 8)) eq '00:15:6d') {

        $board = 'Ubiquiti';

      } elsif (lc(substr($mac, 0, 8)) eq '00:12:cf') {

        $board = 'Accton';

      } else {
        $board = 'Unknown';
      }

    } else {
      $board = $self->device;
    }

     return $board;
}


sub views_count {
    my ( $self, $start, $end) = @_;
    die unless SL::Model::App::validate_dt( $start, $end );

    my $ary_ref = $self->run_query( $views_sql, $start, $end, $self->router_id );

    my $count = 0;
    foreach my $ary ( @{$ary_ref} ) {
      $count += $ary->[1];
    }

    return $count;
}

our $users_sql = <<SQL;
SELECT count(distinct usr_id)
FROM view
WHERE view.cts BETWEEN ? AND ?
AND router_id = ?
SQL

sub users_count {
    my ( $self, $start, $end) = @_;
    die unless SL::Model::App::validate_dt( $start, $end );

    my $ary_ref = $self->run_query( $users_sql, $start, $end, $self->router_id );

    return $ary_ref->[0]->[0];
}



sub last_seen_html {

    my $self = shift;

    my $dt = DateTime::Format::Pg->parse_datetime( $self->last_ping );

    # hack for pacific time
    my $now = DateTime->now;
    $now->set_time_zone('local');
    $now->subtract( hours => 7);
    my $sec = (  $now->epoch - $dt->epoch); 

    my $minutes = sprintf( '%d', $sec / 60 );

    if ( $sec <= 600 ) {
        $self->{'last_seen'} = qq{<font color="green"><b>$sec sec</b></font>};
        $self->{'seen_index'} = 1;
    }
    elsif ( ( $sec > 600 ) && ( $minutes <= 60*2 ) ) {
        $self->{'last_seen'} =
          qq{<font color="red"><b>$minutes min</b></font>};
        $self->{'seen_index'} = 2;
    }
    elsif ( ( $minutes > 60*2 ) && ( $minutes < 60*24 ) ) {
        my $hours = sprintf( '%d', $minutes / 60 );
        $self->{'last_seen'} =
          qq{<font color="orange"><b>$hours hours</b></font>};
        $self->{'seen_index'} = 3;
    }
    else {
        $self->{'last_seen'} =
            '<font color="black">'
          . sprintf( '%d', $minutes / 1440 ) . ' days'
          . '</font>';
        $self->{'seen_index'} = 4;
    }

    return $self->{'last_seen'};
}

1;
