package SL::Model::App;

use strict;
use warnings;

use base qw(DBIx::Class::Schema::Loader);
use SL::Model;

use constant DEBUG => $ENV{SL_DEBUG} || 0;

our %LOADER_OPTIONS;#; = ( relationships => 1 );

if (DEBUG) {
    $LOADER_OPTIONS{debug} = DEBUG;
#    $LOADER_OPTIONS{dump_directory} = '/tmp/sl_model',
}

__PACKAGE__->loader_options( %LOADER_OPTIONS );

my $params_ref = SL::Model->connect_params();

__PACKAGE__->connection(@{$params_ref});

our $schema = __PACKAGE__->connect(SL::Model->connect);

sub schema {
	return $schema;
}

sub validate_dt {
    my (  $start, $end ) = @_;

    return unless $start->isa('DateTime');
    return unless $end->isa('DateTime');
    return unless $end > $start;

    return 1;
}


1;
