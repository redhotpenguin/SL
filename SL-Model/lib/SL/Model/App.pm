package SL::Model::App;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Schema';

__PACKAGE__->load_classes;


# Created by DBIx::Class::Schema::Loader v0.06001 @ 2010-09-02 12:44:05
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:qWJTWSEKMavXJEra/V27QA

use SL::Model;

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



# You can replace this text with custom content, and it will be preserved on regeneration
1;
