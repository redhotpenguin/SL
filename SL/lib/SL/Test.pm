package SL::Test;

use strict;
use warnings;

use base 'Class::Accessor';
use Test::WWW::Mechanize;

my $agent =
"Mozilla/5.0 (Windows; U; Windows NT 5.1; en-US; rv:1.7.12) Gecko/20050915 Firefox/1.0.7";

__PACKAGE__->mk_accessors( qw( mech ) );

sub new {
    my ( $class, %args ) = @_;

    my %self;

    # Add mech
    my $mech = Test::WWW::Mechanize->new( agent => $agent );
    $self{mech} = $mech;

    bless \%self, $class;

    return \%self;
}

1;
