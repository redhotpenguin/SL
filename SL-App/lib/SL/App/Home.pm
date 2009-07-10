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

use constant BLOG_URL => 'http://blog.silverliningnetworks.com/rss.xml';

=head1 METHODS

=over 4

=item C<dispatch_index>

This method serves of the master ad control panel for now

=back

=cut

sub dispatch_index {
    my ( $self, $r ) = @_;

    my $feed = XML::Feed->parse( URI->new(BLOG_URL) );

    my %tmpl_data;
    my @feed;
    if ($feed) {
	foreach my $entry ($feed->entries) {
		push @feed, { title => $entry->title, 'link' => $entry->link,
	date =>  $entry->issued->strftime("%a %b %e,%l:%m %p"),
	content => $entry->content->body, };
	}
	$tmpl_data{rss} = \@feed;
    } else {
    	$r->log->error(sprintf("could not parse feed %s, %s", BLOG_URL,
		XML::Feed->errstr));
    }
    my $output;
    $tmpl->process( 'home.tmpl', \%tmpl_data, \$output, $r ) ||
      return $self->error( $r, $tmpl->error);
    return $self->ok( $r, $output );
}

sub dispatch_welcome {
    my ( $self, $r ) = @_;

    my %tmpl_data;
    my $output;
    $tmpl->process( 'welcome.tmpl', \%tmpl_data, \$output, $r ) ||
      return $self->error( $r, $tmpl->error);
    return $self->ok( $r, $output );
}


1;
