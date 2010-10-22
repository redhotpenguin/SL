package WebService::Yahoo::BOSS::ResultSet;

=head1 NAME

WebService::Yahoo::BOSS::ResultSet - ResultSet class for Yahoo BOSS searches

=cut

use strict;
use warnings;

use Any::Moose;
use XML::LibXML;
use WebService::Yahoo::BOSS::Result;

has 'totalhits'         => ( is => 'ro', isa => 'Int', required => 1 );
has 'results'       => ( is => 'ro', isa => 'ArrayRef[Object]', required => 1);

sub parse {
    my ( $class, $content ) = @_;

    # parse the content
    my $parser   = XML::LibXML->new;
    my $dom      = $parser->load_xml( string => $content );

    # grab the search results first
    my @result_set = $dom->getElementsByTagName('result');
    my @results;
    foreach my $result (@result_set) {

        my %args;
        foreach my $attr (
            qw( abstract date dispurl
            size title url clickurl )
          )
        {

            $args{$attr} =
              $result->getElementsByTagName($attr)->shift->textContent;
        }
        my $res = WebService::Yahoo::BOSS::Result->new(%args);
        push @results, $res;

    }

    my ($web) = $dom->getElementsByTagName('resultset_web');
    my $totalhits = $web->getAttribute('totalhits');
    # <resultset_web count="10" start="0" totalhits="14657798" deephits="96800000">

    my $rs = $class->new( totalhits => $totalhits, results => \@results );

    return $rs;
}

1;
