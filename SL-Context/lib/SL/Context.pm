package SL::Context;

use strict;
use warnings;

our $VERSION = 0.03;

use HTML::TokeParser ();

use constant DEBUG => $ENV{SL_DEBUG} || 0;

=head1 NAME

SL::Context - Contextual analysis

=cut

my %tags = (
    title => 5,
    h1    => 4,
    h2    => 3,
    h3    => 2,
    a     => 1,
    p     => 1,
    td    => 1,
);

sub collect_keywords {
    my ( $self, %args ) = @_;
    my $content_ref = @args{qw(content_ref)};

	if ( $$content_ref eq '' ) {
        warn("$$ SL::Context::collect_keywords missing content_ref") if DEBUG;
        return;
    }

    my $parser = HTML::TokeParser->new($content_ref);
    $parser->attr_encoded(1);

    my %keywords;

    while ( my $token = $parser->get_tag( keys %tags ) ) {

        my $text = $parser->get_text;
        next unless $text =~ m/\w{3,}/;

        my @keywords = split( /\W+/, lc($text) );

        my $increment = $tags{ $token->[0] };

        foreach my $keyword (@keywords) {
            next
              if $keyword =~
m/^(?:what|have|off|want|one|goes|latest|gets|again|top|how|into|not|out|you|has|will|was|from|all|see|img|image|rss|new|com|the|and|or|by|for|are|this|that|who|with|your|set|home|more)$/;
            next if length($keyword) < 3;
            $keywords{$keyword} += $increment;
        }

    }

    foreach my $key ( keys %keywords ) {
        delete $keywords{$key} unless $keywords{$key} > 2;
    }

    my $i = 1;
    foreach
      my $key ( sort { $keywords{$b} <=> $keywords{$a} } keys %keywords )
    {
        delete $keywords{$key}
          if $i++ > 6; # number of keywords

    }

    return \%keywords;
}

1;
