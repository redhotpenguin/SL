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

1;
