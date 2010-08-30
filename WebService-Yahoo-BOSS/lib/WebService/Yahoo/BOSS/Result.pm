package WebService::Yahoo::BOSS::Result;

=head1 NAME

WebService::Yahoo::BOSS::Result - Result class for Yahoo BOSS searches

=cut

use strict;
use warnings;

use Any::Moose;
use XML::LibXML;

has 'abstract' => ( is => 'rw', isa => 'Str', required => 1 );
has 'date'     => ( is => 'ro', isa => 'Str', required => 1 );
has 'dispurl'  => ( is => 'ro', isa => 'Str', required => 1 );
has 'size'     => ( is => 'ro', isa => 'Int', required => 1 );
has 'title'    => ( is => 'rw', isa => 'Str', required => 1 );
has 'url'      => ( is => 'ro', isa => 'Str', required => 1 );
has 'clickurl' => ( is => 'ro', isa => 'Str', required => 1 );

sub parse {
    my ( $class, $content ) = @_;

    # parse the content
    my $parser   = XML::LibXML->new;
    my $dom      = $parser->load_xml( string => $content );
#    warn("dom is " . $dom->toString);
    # <resultset_web count="10" start="0" totalhits="14657798" deephits="96800000">
    my @results = $dom->getElementsByTagName('result');
    my @returns;
    foreach my $result (@results) {


        my %args;
        foreach my $attr (
            qw( abstract date dispurl
            size title url clickurl )
          )
        {

            $args{$attr} =
              $result->getElementsByTagName($attr)->shift->textContent;
        }
        my $res = $class->new(%args);
        push @returns, $res;

    }
    return \@returns;
}

1;
