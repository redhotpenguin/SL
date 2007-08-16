package SL::Model::App::Location;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("Core");
__PACKAGE__->table("location");
__PACKAGE__->add_columns(
    "location_id",
    {
        data_type     => "integer",
        default_value => "nextval('location_location_id_seq'::regclass)",
        is_nullable   => 0,
        size          => 4,
    },
    "ip",
    {
        data_type     => "inet",
        default_value => undef,
        is_nullable   => 0,
        size          => undef,
    },
    "name",
    {
        data_type     => "text",
        default_value => "''::text",
        is_nullable   => 0,
        size          => undef,
    },
    "description",
    {
        data_type     => "text",
        default_value => "''::text",
        is_nullable   => 0,
        size          => undef,
    },
    "street_addr",
    {
        data_type     => "character varying",
        default_value => undef,
        is_nullable   => 1,
        size          => 64,
    },
    "apt_suite",
    {
        data_type     => "character varying",
        default_value => undef,
        is_nullable   => 1,
        size          => 5,
    },
    "zip",
    {
        data_type     => "character varying",
        default_value => undef,
        is_nullable   => 1,
        size          => 9,
    },
    "city",
    {
        data_type     => "character varying",
        default_value => undef,
        is_nullable   => 1,
        size          => 128,
    },
    "state",
    {
        data_type     => "character varying",
        default_value => undef,
        is_nullable   => 1,
        size          => 2,
    },
    "cts",
    {
        data_type     => "timestamp without time zone",
        default_value => "now()",
        is_nullable   => 1,
        size          => 8,
    },
    "mts",
    {
        data_type     => "timestamp without time zone",
        default_value => "now()",
        is_nullable   => 1,
        size          => 8,
    },
    "active",
    {
        data_type     => "boolean",
        default_value => "true",
        is_nullable   => 1,
        size          => 1,
    },
    "default_ok",
    {
        data_type     => "boolean",
        default_value => "true",
        is_nullable   => 1,
        size          => 1,
    },
    "custom_rate_limit",
    {
        data_type     => "character varying",
        default_value => undef,
        is_nullable   => 1,
        size          => 10,
    },
);
__PACKAGE__->set_primary_key("location_id");
__PACKAGE__->has_many(
    "location__ad_groups",
    "SL::Model::App::LocationAdGroup",
    { "foreign.location_id" => "self.location_id" },
);
__PACKAGE__->has_many(
    "router__locations",
    "SL::Model::App::RouterLocation",
    { "foreign.location_id" => "self.location_id" },
);

# Created by DBIx::Class::Schema::Loader v0.04002 @ 2007-08-14 15:56:35
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:JBkgqMM8PKUQw1wb6lkyBw

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
    $sth->bind_param( 3, $self->ip );
    my $rv      = $sth->execute;
    my $ary_ref = $sth->fetchall_arrayref;
    return $ary_ref;
}

our $views_sql = <<SQL;
SELECT ad_id, count(view_id)
FROM view
WHERE view.cts BETWEEN ? AND ?
AND ip = ?
GROUP BY ad_id
SQL


# @views = (
#         { ad => $ad_one_obj, count => '5' },
#         { ad => $ad_two_obj, count => '3' }, );

sub views {
    my ( $self, $start, $end) = @_;
    die unless SL::Model::App::validate_dt( $start, $end );

    my $ary_ref = $self->run_query( $views_sql, $start, $end, $self->ip );

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

    my $ary_ref = $self->run_query( $views_sql, $start, $end, $self->ip );

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
AND ip = ?
GROUP BY ad_id
SQL

# @clicks = (
#         { ad => $ad_one_obj, count => '5' },
#         { ad => $ad_two_obj, count => '3' }, );

sub clicks {
    my ( $self, $start, $end) = @_;
    die unless SL::Model::App::validate_dt( $start, $end );

    my $ary_ref = $self->run_query( $clicks_sql, $start, $end, $self->ip );

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

    my $ary_ref = $self->run_query( $clicks_sql, $start, $end, $self->ip );

    my $count = 0;
    foreach my $ary ( @{$ary_ref} ) {
      $count += $ary->[1];
    }

    return $count;
}

1;
