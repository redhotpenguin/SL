package SL::Model::App::Location;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("Core");
__PACKAGE__->table("location");
__PACKAGE__->add_columns(
  "location_id",
  {
    data_type => "integer",
    default_value => "nextval('location_location_id_seq'::regclass)",
    is_nullable => 0,
    size => 4,
  },
  "ip",
  {
    data_type => "inet",
    default_value => undef,
    is_nullable => 0,
    size => undef,
  },
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
);
__PACKAGE__->set_primary_key("location_id");
__PACKAGE__->add_unique_constraint("location_pkey", ["location_id"]);
__PACKAGE__->has_many(
  "router__locations",
  "SL::Model::App::RouterLocation",
  { "foreign.location_id" => "self.location_id" },
);
__PACKAGE__->has_many(
  "views",
  "SL::Model::App::View",
  { "foreign.location_id" => "self.location_id" },
);


# Created by DBIx::Class::Schema::Loader v0.04005 @ 2009-05-01 19:38:05
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:A2BafaNw4I6aMQCyYcqB1A
# These lines were loaded from '/Users/phred/dev/perl/lib/site_perl/5.8.8/SL/Model/App/Location.pm' found in @INC.# They are now part of the custom portion of this file# for you to hand-edit.  If you do not either delete# this section or remove that file from @INC, this section# will be repeated redundantly when you re-create this# file again via Loader!

use SL::Model::App;
use DateTime::Format::Pg;

sub run_query {
    my ( $self, $sql, $start, $end) = @_;

    die unless $sql && $start && $end;

    unless ( (ref($start) eq 'DateTime') && (ref($end) eq 'DateTime') ) {
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

sub views_list {
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

1;
