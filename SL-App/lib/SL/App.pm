package SL::App;

use strict;
use warnings;

our $VERSION = 0.17;

use Apache2::Const -compile =>
  qw(OK SERVER_ERROR NOT_FOUND M_GET M_POST REDIRECT );
use Apache2::Log       ();
use Apache2::RequestIO ();

use LWP::UserAgent ();
use URI            ();
use Image::Size    ();

use SL::Model::App    ();
use SL::App::Template ();

# don't add the () here
use Data::Dumper;

my $UA = LWP::UserAgent->new;
$UA->timeout(10);    # needs to respond somewhat quickly
our $Tmpl = SL::App::Template->template();

use constant MAX_IMAGE_BYTES => 40_960;
use constant DEBUG => $ENV{SL_DEBUG} || 0;

require Data::Dumper if DEBUG;

=head1 METHODS

=over 4

=item C<dispatch_index>

This is the home page

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
    my $ok = $Tmpl->process( 'index.tmpl', {}, \$output );

    return $self->ok( $r, $output ) if $ok;
    return $self->error( $r, "Template error: " . $Tmpl->error() );
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

sub ua {
    return $UA;
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

	my $uri = eval { URI->new($val) };
	if ($@) {
	    warn("$$ problem creating URI object from url $val: $@");
	    return;
	}

        my $response = eval { $UA->get( $uri ) };
	if ($@) {
	    warn("$$ problem grabbing uri " . $uri->as_string . ": $@");
	    return;
	}

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

        return unless length($pass) > 5;
        return $val;
      }
}


sub check_retype {
    return sub {
        my $dfv    = shift;
        my $val    = $dfv->get_current_constraint_value;
        my $data   = $dfv->get_filtered_data;
        my $pass   = $data->{password};
        my $retype   = $data->{retype};

        return unless $pass eq $retype;
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
        return unless $height == $ad_size->bug_height;
        return unless $width == $ad_size->bug_width;

        return $image_href_val;
      }
}
sub valid_first {

    return sub {
        my $dfv = shift;
        my $val = $dfv->get_current_constraint_value;

        return if $val eq 'First';

        return $val;
      }
}

sub valid_last {

    return sub {
        my $dfv = shift;
        my $val = $dfv->get_current_constraint_value;

        return if $val eq 'Last';

        return $val;
      }
}

sub valid_cvv {
    return sub {
        my $dfv = shift;
        my $val = $dfv->get_current_constraint_value;

        return if $val !~ /^(\d+)$/;

        return $val;
      }
}

sub valid_city {
    return sub {
        my $dfv = shift;
        my $val = $dfv->get_current_constraint_value;

        return if $val =~ /^ex\./;

        return $val;
      }
}

sub valid_street {
    return sub {
        my $dfv = shift;
        my $val = $dfv->get_current_constraint_value;

        return if $val =~ /^ex\./;

        return $val;
      }
}

sub valid_month {
    return sub {
        my $dfv = shift;
        my $val = $dfv->get_current_constraint_value;

        return if $val !~ /^(\d+)$/;

        my $month = $1;

        return if $val < 1 || $val > 12;

        return $month;
      }
}

sub valid_year {
    return sub {
        my $dfv = shift;
        my $val = $dfv->get_current_constraint_value;

        return if $val !~ /^(\d+)$/;

        my $year = $1;

        $val += ( $val < 70 ) ? 2000 : 1900 if $val < 1900;
        my @now = localtime();
        $now[5] += 1900;

        return if ( $val < $now[5] ) || ( $val == $now[5] && $val <= $now[4] );

        return $year;
      }
}


1;
