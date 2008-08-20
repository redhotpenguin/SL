package SL::Apache::App;

use strict;
use warnings;

our $VERSION = 0.16;

use Apache2::Const -compile =>
  qw(OK SERVER_ERROR NOT_FOUND M_GET M_POST REDIRECT );
use Apache2::Log       ();
use Apache2::RequestIO ();

use LWP::UserAgent ();
use URI            ();
use Image::Size    ();

use SL::Model::App    ();
use SL::App::Template ();

my $UA = LWP::UserAgent->new;
$UA->timeout(10);    # needs to respond somewhat quickly
our $TMPL = SL::App::Template->template();

use constant MAX_IMAGE_BYTES => 10_240;
use constant DEBUG => $ENV{SL_DEBUG} || 0;

require Data::Dumper if DEBUG;

=head1 METHODS

=over 4

=item C<dispatch_index>

This method serves of the master ad control panel for now

=back

=cut

sub dispatch_index {
    my ( $self, $r ) = @_;

    if ( $r->user ) {

        $r->log->debug( "$$ authenticated user " . $r->user . " detected" )
          if DEBUG;

        # authenticated user, send to the dashboard home page

        $r->headers_out->set(
            Location => $r->construct_url('/app/home/index') );
        return Apache2::Const::REDIRECT;
    }

    my $output;
    my $ok = $TMPL->process( 'index.tmpl', {}, \$output );

    return $self->ok( $r, $output ) if $ok;
    return $self->error( $r, "Template error: " . $TMPL->error() );
}

sub ok {
    my ( $self, $r, $output ) = @_;

    # send successful response
    $r->no_cache(1);
    $r->content_type('text/html');
    $r->print($output);
    return Apache2::Const::OK;
}

sub error {
    my ( $self, $r, $error ) = @_;
    $r->log->error($error);
    return Apache2::Const::SERVER_ERROR;
}

sub _results_to_errors {
    my ( $self, $results ) = @_;
    my %errors;

    if ( $results->has_missing ) {
        %{ $errors{missing} } = map { $_ => 1 } $results->missing;
    }
    if ( $results->has_invalid ) {
        %{ $errors{invalid} } = map { $_ => 1 } $results->invalid;
    }
    return \%errors;
}

sub valid_link {
    return sub {
        my $dfv = shift;
        my $val = $dfv->get_current_constraint_value;

        my $response = $UA->get( URI->new($val) );
        return $val if $response->is_success;
        return;    # oops didn't validate
      }
}

sub check_password {
    return sub {
        my $dfv    = shift;
        my $val    = $dfv->get_current_constraint_value;
        my $data   = $dfv->get_filtered_data;
        my $pass   = $data->{password};
        my $retype = $data->{retype};

        return unless ( $pass eq $retype );
        return unless length($pass) > 4;
        return $val;
      }
}

sub image_zone {
    return sub {
        my $dfv            = shift;
        my $image_href_val = $dfv->get_current_constraint_value;
        my $data           = $dfv->get_filtered_data;
        my $image_href     = $data->{image_href};
        my $ad_size_id     = $data->{ad_size_id};

        my ($ad_size) = SL::Model::App->resultset('AdSize')->search({
            ad_size_id =>  $ad_size_id });

        return unless $ad_size;
        my $response = $UA->get( URI->new($image_href) );

        my ( $width, $height ) = Image::Size::imgsize( \$response->content );

        # image too big?
        return unless $response->headers->header('content-length') < MAX_IMAGE_BYTES;

        # check the image height
        # only allow bugs that are 3x1 ratio width to height or less
        if ($ad_size->ad_size_id < 4) {
            return unless $height == $ad_size->height;
            return unless $width < ( $ad_size->height * 3 );
        } else {
            return unless $width == $ad_size->width;
            return unless $height < ( $ad_size->width * 3 );
        }


        return $image_href_val;
      }
}

1;
