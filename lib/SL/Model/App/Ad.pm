package SL::Model::Ad;

use strict;
use warnings;

use SL::Object;
our @ISA = qw(SL::Object);

__PACKAGE__->meta->table('ad');
__PACKAGE__->meta->auto_initialize;

1;
