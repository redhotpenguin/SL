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
    default_value => "'http://www.silverliningnetworks.com/network/'::text",
    is_nullable => 1,
    size => undef,
  },
  "firmware_version",
  {
    data_type => "character varying",
    default_value => "''::character varying",
    is_nullable => 1,
    size => 4,
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
  { data_type => "integer", default_value => 1, is_nullable => 0, size => 4 },
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
  "gateway",
  {
    data_type => "boolean",
    default_value => "true",
    is_nullable => 0,
    size => 1,
  },
);
__PACKAGE__->set_primary_key("router_id");
__PACKAGE__->add_unique_constraint("router_pkey", ["router_id"]);
__PACKAGE__->add_unique_constraint("madaddr_uniq", ["macaddr"]);
__PACKAGE__->belongs_to(
  "account_id",
  "SL::Model::App::Account",
  { account_id => "account_id" },
);
__PACKAGE__->has_many(
  "router__ad_zones",
  "SL::Model::App::RouterAdZone",
  { "foreign.router_id" => "self.router_id" },
);
__PACKAGE__->has_many(
  "router__locations",
  "SL::Model::App::RouterLocation",
  { "foreign.router_id" => "self.router_id" },
);
__PACKAGE__->has_many(
  "views",
  "SL::Model::App::View",
  { "foreign.router_id" => "self.router_id" },
);


# Created by DBIx::Class::Schema::Loader v0.04006 @ 2009-05-13 20:13:04
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:kkiwNx4xbPYvfqpHGLueRA
# These lines were loaded from '/Users/phred/dev/perl/lib/site_perl/5.8.8/SL/Model/App/Router.pm' found in @INC.# They are now part of the custom portion of this file# for you to hand-edit.  If you do not either delete# this section or remove that file from @INC, this section# will be repeated redundantly when you re-create this# file again via Loader!

use SL::Model::App;
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

sub mac__to__om_mac {
	my $mac = shift or die 'no mac passed';

	my $last_two = substr($ mac, length($mac) - 2, length($mac));
	$last_two = sprintf('%02x', sprintf('%d', hex($last_two))-1);
	substr($mac, length($mac) - 2, length($mac), $last_two);
	substr($mac, 0, 2, '00');
	return $mac;
}

sub om_mac__to__mac {
	my $mac = shift or die 'no mac passed';

	my $last_two = substr($mac, length($mac) - 2, length($mac));
	$last_two = sprintf('%02x', sprintf('%d', hex($last_two))+1);
	substr($mac, length($mac) - 2, length($mac), $last_two);
	substr($mac, 0, 2, '06');
	return $mac;
}



sub displaymac {
	my $self = shift;

	my $mac = $self->macaddr;
	if (substr(uc($mac), 0, 9) eq '06:12:CF:') {
		# translate
		$mac = mac__to__om_mac($mac);
	}
	return $mac;
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



1;
