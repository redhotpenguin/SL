package SL::Model::App;

use strict;
use warnings;

use SL::Model;
use base qw(DBIx::Class::Schema::Loader);

our $DEBUG = 1;

__PACKAGE__->loader_options(
	relationships => 1,
	debug => $DEBUG,
#	moniker_map => sub { return join '::', split /[\W_]+/, shift },
);

my $params_ref = SL::Model->connect_params();
__PACKAGE__->connection(@{$params_ref});

1;