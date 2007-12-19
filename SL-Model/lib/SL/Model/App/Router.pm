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
    data_type => "character",
    default_value => undef,
    is_nullable => 1,
    size => 12,
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
  "replace_port",
  { data_type => "smallint", default_value => 8135, is_nullable => 1, size => 2 },
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
  "feed_google",
  {
    data_type => "boolean",
    default_value => "false",
    is_nullable => 1,
    size => 1,
  },
  "feed_linkshare",
  {
    data_type => "boolean",
    default_value => "false",
    is_nullable => 1,
    size => 1,
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
);
__PACKAGE__->set_primary_key("router_id");
__PACKAGE__->has_many(
  "views",
  "SL::Model::App::View",
  { "foreign.router_id" => "self.router_id" },
);
__PACKAGE__->has_many(
  "router__ad_groups",
  "SL::Model::App::RouterAdGroup",
  { "foreign.router_id" => "self.router_id" },
);
__PACKAGE__->has_many(
  "router__locations",
  "SL::Model::App::RouterLocation",
  { "foreign.router_id" => "self.router_id" },
);
__PACKAGE__->has_many(
  "router__regs",
  "SL::Model::App::RouterReg",
  { "foreign.router_id" => "self.router_id" },
);


# Created by DBIx::Class::Schema::Loader v0.04002 @ 2007-12-18 15:37:05
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:4/k+Hf1HfHP78EUCq6zn1g

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
SELECT ad_id, count(view_id)
FROM view
WHERE view.cts BETWEEN ? AND ?
AND router_id = ?
GROUP BY ad_id
SQL


# @views = (
#         { ad => $ad_one_obj, count => '5' },
#         { ad => $ad_two_obj, count => '3' }, );

sub ad_views {
    my ( $self, $start, $end) = @_;
    die unless SL::Model::App::validate_dt( $start, $end );

    my $ary_ref = $self->run_query( $views_sql, $start, $end, $self->router_id );
    my @views;

    foreach my $ary ( @{$ary_ref} ) {
        my ($ad) =
          SL::Model::App->resultset('Ad')->search( { ad_id => $ary->[0] } );
        push @views, { ad => $ad, count => $ary->[1] };
    }

    my $count = 0;
    foreach my $view (@views) {
        $count += $view->{count};
    }

    return ( $count, \@views );
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

our $clicks_sql = <<SQL;
SELECT ad_id, count(click_id)
FROM click
WHERE cts BETWEEN ? AND ?
AND router_id = ?
GROUP BY ad_id
SQL

# @clicks = (
#         { ad => $ad_one_obj, count => '5' },
#         { ad => $ad_two_obj, count => '3' }, );

sub ad_clicks {
    my ( $self, $start, $end) = @_;
    die unless SL::Model::App::validate_dt( $start, $end );

    my $ary_ref = $self->run_query( $clicks_sql, $start, $end, $self->router_id );

    my @clicks;
    foreach my $ary ( @{$ary_ref} ) {
        my ($ad) =
          SL::Model::App->resultset('Ad')->search( { ad_id => $ary->[0] } );
        push @clicks, { ad => $ad, count => $ary->[1] };
    }

    my $count = 0;
    foreach my $click (@clicks) {
        $count += $click->{count};
    }

    return ( $count, \@clicks );
}

sub clicks_count {
    my ( $self, $start, $end) = @_;
    die unless SL::Model::App::validate_dt( $start, $end );

    my $ary_ref = $self->run_query( $clicks_sql, $start, $end, $self->router_id );

    my $count = 0;
    foreach my $ary ( @{$ary_ref} ) {
      $count += $ary->[1];
    }

    return $count;
}

1;
