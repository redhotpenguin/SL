package SL::Util;

use strict;
use warnings;

use HTML::TokeParser;

sub not_html {
    my $content_type = shift;
    if ( $content_type !~ m/text\/html/ and $content_type !~ m/xml/ ) {
        return 1;
    }
}

sub extract_links {
    my ( $class, $content, $r) = @_;
    my @links;
    my $parser = HTML::TokeParser->new( \$content );
    while ( my $token = $parser->get_tag('a') ) {

        my $tag   = $token->[0];
        my $attrs = $token->[1];
        my $url   = $attrs->{'href'};
		
		# potential bug here for non http links
		# fixup relative links
        unless ($url =~ m{^http://}) {
			$url = 'http://' . $r->hostname . $url;
		}
		push @links, $url;
    }
    return \@links;
}

1;
