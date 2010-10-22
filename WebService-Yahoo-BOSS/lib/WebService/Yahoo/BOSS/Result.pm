package WebService::Yahoo::BOSS::Result;

=head1 NAME

WebService::Yahoo::BOSS::Result - Result class for Yahoo BOSS searches

=cut

use strict;
use warnings;

use Any::Moose;

has 'abstract' => ( is => 'rw', isa => 'Str', required => 1 );
has 'date'     => ( is => 'ro', isa => 'Str', required => 1 );
has 'dispurl'  => ( is => 'ro', isa => 'Str', required => 1 );
has 'size'     => ( is => 'ro', isa => 'Int', required => 1 );
has 'title'    => ( is => 'rw', isa => 'Str', required => 1 );
has 'url'      => ( is => 'ro', isa => 'Str', required => 1 );
has 'clickurl' => ( is => 'ro', isa => 'Str', required => 1 );

1;
