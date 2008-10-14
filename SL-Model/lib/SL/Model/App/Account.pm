package SL::Model::App::Account;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("Core");
__PACKAGE__->table("account");
__PACKAGE__->add_columns(
  "account_id",
  {
    data_type => "integer",
    default_value => "nextval('account_account_id_seq'::regclass)",
    is_nullable => 0,
    size => 4,
  },
  "name",
  {
    data_type => "text",
    default_value => undef,
    is_nullable => 0,
    size => undef,
  },
  "premium",
  {
    data_type => "boolean",
    default_value => "false",
    is_nullable => 0,
    size => 1,
  },
  "close_box",
  {
    data_type => "boolean",
    default_value => "true",
    is_nullable => 0,
    size => 1,
  },
  "active",
  {
    data_type => "boolean",
    default_value => "true",
    is_nullable => 1,
    size => 1,
  },
);
__PACKAGE__->set_primary_key("account_id");
__PACKAGE__->add_unique_constraint("account_pkey", ["account_id"]);
__PACKAGE__->has_many(
  "account__ad_zones",
  "SL::Model::App::AccountAdZone",
  { "foreign.account_id" => "self.account_id" },
);
__PACKAGE__->has_many(
  "ad_zones",
  "SL::Model::App::AdZone",
  { "foreign.account_id" => "self.account_id" },
);
__PACKAGE__->has_many(
  "bugs",
  "SL::Model::App::Bug",
  { "foreign.account_id" => "self.account_id" },
);
__PACKAGE__->has_many(
  "payments",
  "SL::Model::App::Payment",
  { "foreign.account_id" => "self.account_id" },
);
__PACKAGE__->has_many(
  "regs",
  "SL::Model::App::Reg",
  { "foreign.account_id" => "self.account_id" },
);
__PACKAGE__->has_many(
  "routers",
  "SL::Model::App::Router",
  { "foreign.account_id" => "self.account_id" },
);


# Created by DBIx::Class::Schema::Loader v0.04005 @ 2008-07-14 21:34:33
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:GxKKi49s3IE+qdqlEstWJQ

use File::Path       ();
use Digest::MD5      ();

use SL::Model::App   ();
use SL::Config       ();

our $config = SL::Config->new();

use constant DEBUG => $ENV{SL_DEBUG} || 1;
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
  return join('/', Digest::MD5::md5_hex( $self->name ), 'report');
}


sub update_example_ad_zones {
    my $self = shift;

    my %base_example_ad_zones = map { $_->name => $_ }
        SL::Model::App->resultset('AdZone')->search({
           account_id => 1,
           name => { like => 'SLN Example%', }, });

    my %account_example_ad_zones = map { $_->name => $_ }
        SL::Model::App->resultset('AdZone')->search({
           account_id => $self->account_id,
           name => { like => 'SLN Example%', }, });

    foreach my $base_example ( keys %base_example_ad_zones ) {

        # don't modify existing examples slick.  maybe some day.  They might modify
        # theirs and then suddenly you fucked up their production ad zones.  Nice :)
        next if $account_example_ad_zones{$base_example};

        my $example = $base_example_ad_zones{$base_example};
        my $ex_bug = $example->bug_id;

        # create one
         my $bug_example = SL::Model::App->resultset('Bug')->new({
                image_href => $ex_bug->image_href,
                link_href  => $ex_bug->link_href,
                account_id => $self->account_id,
                ad_size_id => $ex_bug->ad_size_id->ad_size_id, });

          $bug_example->insert;
          $bug_example->update;

        # add the ad zone
        my $new_ad_zone = SL::Model::App->resultset('AdZone')->new({
                account_id => $self->account_id,
                bug_id => $bug_example->bug_id,
                reg_id => 1,
                name => $example->name,
                code => $example->code,
                code_double => $example->code_double,
                ad_size_id => $example->ad_size_id->ad_size_id,
            });

        $new_ad_zone->insert;
        $new_ad_zone->update;

        warn("added example ad zone " . $new_ad_zone->name ) if DEBUG;
    }


}


sub get_ad_zones {
    my $self = shift;

    # ad zones allowed for this user
    my @ad_zones = SL::Model::App->resultset('AdZone')->search({
    		     active => 't',
                     account_id => $self->account_id });

    return unless scalar(@ad_zones) > 0;

    # get router count for each ad zone
    $self->process_ad_zone($_) for @ad_zones;

    return @ad_zones;
}

sub process_ad_zone {
    my ( $self, $ad_zone ) = @_;

    # get routers for this account
    my @routers = SL::Model::App->resultset('Router')->search({
             account_id => $self->account_id });

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

    my $router_name = $router->name || $router->macaddr ||
        sprintf('empty router id %d', $router->router_id);
    print "===> processing router $router_name\n" if DEBUG;
    my $count = $router->views_count( $start, $end );
        $total += $count;

        $views_hashref->{routers}->{ $router->router_id }->{count} =
          $count || 0;
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
    foreach my $router ( sort { $a->router_id <=> $b->router_id }
                         @{$routers_aryref} ) {

	    my $router_name = $router->name || $router->macaddr ||
	        sprintf('empty router id %d', $router->router_id);

        print "===> processing router $router_name\n" if DEBUG;
	    my $count = $router->users_count( $start, $end );
        $total += $count;

        $users_hashref->{routers}->{ $router->router_id }->{count} =
          $count || 0;
    }
    $users_hashref->{total} = $total;

    return $users_hashref;
}

sub users_unique {
    my ( $self, $start, $end, $routers_aryref ) = @_;
    my $users_hashref = $self->users_count( $start, $end, $routers_aryref);

    return $users_hashref->{total};
}

1;
