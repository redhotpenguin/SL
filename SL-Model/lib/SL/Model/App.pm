package SL::Model::App;

use strict;
use warnings;

use base 'DBIx::Class::Schema';

__PACKAGE__->load_classes;


# Created by DBIx::Class::Schema::Loader v0.04999_07 @ 2009-06-14 16:15:26
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:GmQQQnXkboKufTdaKMuVqg

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
