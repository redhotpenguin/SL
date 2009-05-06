package SL::App::Home;

use strict;
use warnings;

use Apache2::Const -compile => qw(OK SERVER_ERROR NOT_FOUND M_GET M_POST);
use Apache2::Log ();

use base 'SL::App';

use URI               ();
use XML::Feed         ();
use SL::App::Template ();
our $tmpl = SL::App::Template->template();

#use constant FORUM_URL => 'http://forums.silverliningnetworks.com/forums/5/posts.rss';
use constant FORUM_URL => 'http://forums.silverliningnetworks.com/posts.rss';

=head1 METHODS

=over 4

=item C<dispatch_index>

This method serves of the master ad control panel for now

=back

=cut

sub dispatch_index {
    my ( $self, $r ) = @_;

    my $feed = XML::Feed->parse( URI->new(FORUM_URL) );

    my %tmpl_data;
    my @feed;
    if ($feed) {
	foreach my $entry ($feed->entries) {
		push @feed, { title => $entry->title, 'link' => $entry->link,
			content => $entry->content->body };
	}
	$tmpl_data{rss} = \@feed;
    } else {
    	$r->log->error(sprintf("could not parse feed %s, %s", FORUM_URL,
		XML::Feed->errstr));
    }
    my $output;
    $tmpl->process( 'home.tmpl', \%tmpl_data, \$output, $r ) ||
      return $self->error( $r, $tmpl->error);
    return $self->ok( $r, $output );
}

1;
