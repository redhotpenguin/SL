package SL::Model::App::Router;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("Core");
__PACKAGE__->table("router");
__PACKAGE__->add_columns(
  "router_id",
  {
    data_type => "integer",
    default_value => "nextval('router_router_id_seq'::regclass)",
    is_auto_increment => 1,
    is_nullable => 0,
    size => 4,
  },
  "serial_number",
  {
    data_type => "character varying",
    default_value => undef,
    is_nullable => 1,
    size => 24,
  },
  "macaddr",
  { data_type => "macaddr", default_value => undef, is_nullable => 1, size => 6 },
  "cts",
  {
    data_type => "timestamp without time zone",
    default_value => "now()",
    is_nullable => 1,
    size => 8,
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
  "proxy",
  {
    data_type => "inet",
    default_value => undef,
    is_nullable => 1,
    size => undef,
  },
  "description",
  {
    data_type => "text",
    default_value => undef,
    is_nullable => 1,
    size => undef,
  },
  "name",
  {
    data_type => "text",
    default_value => undef,
    is_nullable => 1,
    size => undef,
  },
  "splash_timeout",
  { data_type => "integer", default_value => 60, is_nullable => 1, size => 4 },
  "splash_href",
  {
    data_type => "text",
    default_value => "''::text",
    is_nullable => 1,
    size => undef,
  },
  "firmware_version",
  {
    data_type => "text",
    default_value => "''::text",
    is_nullable => 1,
    size => undef,
  },
  "ssid",
  {
    data_type => "text",
    default_value => "''::text",
    is_nullable => 1,
    size => undef,
  },
  "passwd_event",
  {
    data_type => "text",
    default_value => "''::text",
    is_nullable => 1,
    size => undef,
  },
  "firmware_event",
  {
    data_type => "text",
    default_value => "''::text",
    is_nullable => 1,
    size => undef,
  },
  "ssid_event",
  {
    data_type => "text",
    default_value => "''::text",
    is_nullable => 1,
    size => undef,
  },
  "reboot_event",
  {
    data_type => "text",
    default_value => "''::text",
    is_nullable => 1,
    size => undef,
  },
  "halt_event",
  {
    data_type => "text",
    default_value => "''::text",
    is_nullable => 1,
    size => undef,
  },
  "last_ping",
  {
    data_type => "timestamp without time zone",
    default_value => "now()",
    is_nullable => 1,
    size => 8,
  },
  "views_daily",
  { data_type => "integer", default_value => 0, is_nullable => 0, size => 4 },
  "account_id",
  {
    data_type => "integer",
    default_value => 1,
    is_foreign_key => 1,
    is_nullable => 0,
    size => 4,
  },
  "wan_ip",
  {
    data_type => "inet",
    default_value => undef,
    is_nullable => 1,
    size => undef,
  },
  "lan_ip",
  {
    data_type => "inet",
    default_value => undef,
    is_nullable => 1,
    size => undef,
  },
  "show_aaa_link",
  {
    data_type => "boolean",
    default_value => "false",
    is_nullable => 0,
    size => 1,
  },
  "device",
  {
    data_type => "character varying",
    default_value => "''::character varying",
    is_nullable => 1,
    size => 64,
  },
  "adserving",
  {
    data_type => "boolean",
    default_value => "false",
    is_nullable => 0,
    size => 1,
  },
  "notes",
  {
    data_type => "text",
    default_value => "''::text",
    is_nullable => 0,
    size => undef,
  },
  "lat",
  {
    data_type => "double precision",
    default_value => undef,
    is_nullable => 1,
    size => 8,
  },
  "lng",
  {
    data_type => "double precision",
    default_value => undef,
    is_nullable => 1,
    size => 8,
  },
  "ip",
  {
    data_type => "inet",
    default_value => undef,
    is_nullable => 1,
    size => undef,
  },
  "users_daily",
  { data_type => "integer", default_value => 0, is_nullable => 0, size => 4 },
  "traffic_daily",
  { data_type => "integer", default_value => 0, is_nullable => 0, size => 4 },
  "memfree",
  { data_type => "integer", default_value => 0, is_nullable => 0, size => 4 },
  "clients",
  { data_type => "integer", default_value => 0, is_nullable => 0, size => 4 },
  "hops",
  { data_type => "integer", default_value => 0, is_nullable => 0, size => 4 },
  "kbup",
  { data_type => "integer", default_value => 0, is_nullable => 0, size => 4 },
  "kbdown",
  { data_type => "integer", default_value => 0, is_nullable => 0, size => 4 },
  "neighbors",
  {
    data_type => "text",
    default_value => "''::text",
    is_nullable => 0,
    size => undef,
  },
  "gateway_quality",
  {
    data_type => "text",
    default_value => "''::text",
    is_nullable => 0,
    size => undef,
  },
  "routes",
  {
    data_type => "text",
    default_value => "''::text",
    is_nullable => 0,
    size => undef,
  },
  "load",
  {
    data_type => "text",
    default_value => "''::text",
    is_nullable => 0,
    size => undef,
  },
  "download_last",
  { data_type => "integer", default_value => 0, is_nullable => 0, size => 4 },
  "download_average",
  { data_type => "integer", default_value => 0, is_nullable => 0, size => 4 },
  "mesh_ip",
  {
    data_type => "inet",
    default_value => undef,
    is_nullable => 1,
    size => undef,
  },
  "checkin_status",
  {
    data_type => "text",
    default_value => "'No checkin history'::text",
    is_nullable => 0,
    size => undef,
  },
  "speed_test",
  {
    data_type => "text",
    default_value => "'No speed test data'::text",
    is_nullable => 0,
    size => undef,
  },
  "gateway",
  {
    data_type => "inet",
    default_value => undef,
    is_nullable => 1,
    size => undef,
  },
  "firmware_build",
  {
    data_type => "text",
    default_value => "''::text",
    is_nullable => 0,
    size => undef,
  },
  "users_monthly",
  { data_type => "integer", default_value => 0, is_nullable => 0, size => 4 },
  "megabytes_monthly",
  { data_type => "integer", default_value => 0, is_nullable => 0, size => 4 },
  "robin",
  {
    data_type => "text",
    default_value => "'0'::text",
    is_nullable => 0,
    size => undef,
  },
  "default_skips",
  {
    data_type => "text",
    default_value => '',
    is_nullable => 0,
    size => undef,
  },
  "custom_skips",
  {
    data_type => "text",
    default_value => '',
    is_nullable => 0,
    size => undef,
  },
);
__PACKAGE__->set_primary_key("router_id");
__PACKAGE__->add_unique_constraint("madaddr_uniq", ["macaddr"]);
__PACKAGE__->has_many(
  "checkins",
  "SL::Model::App::Checkin",
  { "foreign.router_id" => "self.router_id" },
);
__PACKAGE__->belongs_to(
  "account",
  "SL::Model::App::Account",
  { account_id => "account_id" },
);
__PACKAGE__->has_many(
  "router__ad_zones",
  "SL::Model::App::RouterAdZone",
  { "foreign.router_id" => "self.router_id" },
);
__PACKAGE__->has_many(
  "usertracks",
  "SL::Model::App::Usertrack",
  { "foreign.router_id" => "self.router_id" },
);


# Created by DBIx::Class::Schema::Loader v0.04999_08 @ 2009-09-15 15:16:53
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:mlHo+GgLIZh6TMQHS8iCxQ
# These lines were loaded from '/home/phred/dev/perl/lib/site_perl/5.8.9/SL/Model/App/Router.pm' found in @INC.
# They are now part of the custom portion of this file
# for you to hand-edit.  If you do not either delete
# this section or remove that file from @INC, this section
# will be repeated redundantly when you re-create this
# file again via Loader!

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
    $now->subtract( hours => 8);
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
# End of lines loaded from '/Users/phred/dev/perl/lib/site_perl/5.8.8/SL/Model/App/Router.pm' 
