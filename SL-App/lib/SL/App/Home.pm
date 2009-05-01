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

    my $feed = XML::Feed->parse( URI->new(FORUM_URL) ) or die;

    my %tmpl_data = ( rss_list => $feed->entries );
    my $output;
    my $ok = $tmpl->process( 'home.tmpl', \%tmpl_data, \$output, $r );
    $ok
      ? return $self->ok( $r, $output )
      : return $self->error( $r, "Template error: " . $tmpl->error() );
}

1;