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
use Digest::MD5    ();

use SL::Model::App    ();
use SL::App::Template ();
use Config::SL; 

# don't add the () here
use Data::Dumper;

my $Ua = LWP::UserAgent->new;
$Ua->agent(
'Mozilla/5.0 (Macintosh; U; Intel Mac OS X 10.5; en-US; rv:1.9.1.2) Gecko/20090729 Firefox/3.5.2'
);
$Ua->timeout(10);    # needs to respond somewhat quickly
our $Tmpl = SL::App::Template->template();

our $Tech_error = 'A technical problem occurred, please try again';
our $From       = 'SLN Support <support@silverliningnetworks.com>';
our $Signup     = 'SLN Signup <signup@silverliningnetworks.com>';

our $Config = Config::SL->new;

use constant MAX_IMAGE_BYTES => 40_960;
use constant DEBUG           => 1; #$ENV{SL_DEBUG} || 0;
use constant VERBOSE_DEBUG   => $ENV{SL_VERBOSE_DEBUG} || 0;

=head1 METHODS

=over 4

=item C<dispatch_index>

This is the home page

=back

=cut

sub dispatch_index {
    my ( $self, $r ) = @_;

    if ( $r->user ) {

        $r->log->debug( sprintf( 'authd user %s, redirecting', $r->user ) )
          if DEBUG;

        # authenticated user, send to the dashboard home page
        $r->headers_out->set(
            Location => $Config->sl_app_proxy . '/app/home/index' );

    }
    else {
        my $location = $Config->sl_app_proxy . '/login';
        $r->log->debug("unknown user, redirecting to $location") if DEBUG;

        $r->headers_out->set( Location => $location );

    }

    $r->no_cache(1);
    return Apache2::Const::REDIRECT;
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
    return $Ua;
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

        my $response = eval { $Ua->get($uri) };
        if ($@) {
            warn( "$$ problem grabbing uri " . $uri->as_string . ": $@" );
            return;
        }

        return $val if $response->is_success;
        return;    # oops didn't validate
      }
}

sub check_password {
    return sub {
        my $dfv  = shift;
        my $val  = $dfv->get_current_constraint_value;
        my $data = $dfv->get_filtered_data;
        my $pass = $data->{password};

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
        my $retype = $data->{retype};

        return unless $pass eq $retype;
        return $val;
      }
}

sub valid_branding_image {
    return sub {
        my $dfv            = shift;
        my $image_href_val = $dfv->get_current_constraint_value;
        my $data           = $dfv->get_filtered_data;
        my $image_href     = $data->{image_href};

        my $response = $Ua->get( URI->new($image_href) );

        unless ( $response->is_success ) {

            $dfv->{image_err} = { missing => 1 };
            return;
        }

        my ( $width, $height ) = Image::Size::imgsize( \$response->content );

        unless ( ( $height == 90 )
            && ( ( $width == 200 ) or ( $width == 120 ) ) )
        {
            $dfv->{image_err} = { width => $width, height => $height };
            return;
        }

        $data->{width} = $width;

        return $width;
      }
}

sub valid_splash_ad {
    return sub {
        my $dfv            = shift;
        my $image_href_val = $dfv->get_current_constraint_value;
        my $data           = $dfv->get_filtered_data;
        my $image_href     = $data->{image_href};

        my $response = $Ua->get( URI->new($image_href) );

        unless ( $response->is_success ) {
            $dfv->{image_err} = { missing => 1 };
            return;
        }

        my ( $width, $height ) = Image::Size::imgsize( \$response->content );

        unless ( ( $height == 250 ) && ( $width == 300 ) ) {
            $dfv->{image_err} = { width => $width, height => $height };
            return;
        }

        $data->{width} = $width;

        return $width;
      }
}

sub valid_banner_ad {
    return sub {
        my $dfv            = shift;
        my $image_href_val = $dfv->get_current_constraint_value;
        my $data           = $dfv->get_filtered_data;
        my $image_href     = $data->{image_href};

        my $response = $Ua->get( URI->new($image_href) );

        warn( "response is " . Data::Dumper::Dumper($response) ) if DEBUG;

        unless ( $response->is_success ) {

            $dfv->{image_err} = { missing => 1 };
            warn("could not find image at $image_href") if DEBUG;
            return;
        }

        my ( $width, $height ) = Image::Size::imgsize( \$response->content );

        unless ( ( $width == 728 ) && ( $height == 90 ) ) {

            $dfv->{image_err} = { width => $width, height => $height };
            warn(
                sprintf(
                    "image size width %s, height %s for url $image_href",
                    $width, $height
                )
            ) if DEBUG;
            return;
        }

        $data->{width} = $width;

        return $width;
      }
}

sub valid_swap_ad {
    return sub {
        my $dfv            = shift;
        my $image_href_val = $dfv->get_current_constraint_value;
        my $data           = $dfv->get_filtered_data;
        my $image_href     = $data->{image_href};

        my $response = $Ua->get( URI->new($image_href) );

        warn( "response is " . Data::Dumper::Dumper($response) ) if DEBUG;

        unless ( $response->is_success ) {

            $dfv->{image_err} = { missing => 1 };
            warn("could not find image at $image_href") if DEBUG;
            return;
        }

        my ( $width, $height ) = Image::Size::imgsize( \$response->content );

        my ($ad_size_obj) =
          SL::Model::App->resultset('AdSize')
          ->search( { ad_size_id => $data->{ad_size_id}, } );

        unless ( ( $width == $ad_size_obj->width )
            && ( $height == $ad_size_obj->height ) )
        {

            $dfv->{image_err} = { width => $width, height => $height };
            warn(
                sprintf(
                    "image size width %s, height %s for url $image_href",
                    $width, $height
                )
            ) if DEBUG;
            return;
        }

        $data->{width} = $width;

        return $width;
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

sub valid_mac {
    return sub {
        my $dfv = shift;
        my $val = $dfv->get_current_constraint_value;

        # sample mac, invalid
        return if lc($val) eq '00:17:f2:43:38:bd';

        return $val if check_mac($val);

        return;
      }
}

sub check_mac {
    my $mac = shift;

    return 1 if ( $mac =~ m/^([0-9a-fA-F]{2}([:-]|$)){6}$/i );

    return;
}

sub valid_serial {
    return sub {
        my $dfv = shift;
        my $val = $dfv->get_current_constraint_value;

        return if $val eq 'CL7A0F318014';

        return $val;
      }
}

sub splash_timeout {
    return sub {
        my $dfv = shift;
        my $val = $dfv->get_current_constraint_value;
        return $val if ( $val =~ m/^\d{1,3}$/ );
        return;
      }
}

sub splash_href {
    return sub {
        my $dfv = shift;
        my $val = $dfv->get_current_constraint_value;

        return $val if ( $val =~ m/^https?:\/\/\w+/ );
        return;
      }
}

sub valid_aaa_plan {
    return sub {
        my $dfv = shift;
        my $val = $dfv->get_current_constraint_value;

        return $val if ( $val =~ m/(?:one|four|day|month)/ );
        return;
      }
}

sub valid_username {
    return sub {
        my $dfv   = shift;
        my $val   = $dfv->get_current_constraint_value;
        my $data  = $dfv->get_filtered_data;
        my $email = $data->{email};
        my $pass  = $data->{password};

        return if !$pass;
        my ($reg) =
          SL::Model::App->resultset('Reg')->search( { email => $email } );

        # new user, ok
        return $val if !$reg;

        # existing user, make sure the password matches
        if ( $reg->password_md5 eq Digest::MD5::md5_hex($pass) ) {

            # passwords match
            return $val;
        }
        else {
            warn(
                sprintf(
                    "existing user %s registering with invalid pass %s",
                    $reg->email, $pass
                )
            );
            return;
        }
      }
}

sub sldatetime {
    my ( $self, $mts ) = @_;

    return DateTime::Format::Pg->parse_datetime($mts)
      ->strftime("%m/%d/%y (%I:%M %p)");

}

sub format_adzone_list {
    my ( $class, $ad_zones ) = @_;

    foreach my $ad_zone ( @{$ad_zones} ) {

        if (DEBUG) {

            # HACK for dev environment
            $ad_zone->mts( $ad_zone->mts );
        }
        else {
            $ad_zone->mts( $class->sldatetime( $ad_zone->mts ) );
        }

        my $len = 22;
        $len = 30 if $ad_zone->ad_size->swap;

        if ( length( $ad_zone->name ) > $len ) {
            $ad_zone->name( substr( $ad_zone->name, 0, 19 ) . '...' );
        }
    }

    return 1;
}

sub display_weight {
    my ( $self, $rate ) = @_;

    my $weight;

    if ( $rate eq 'low' ) {

        $weight = 1;
    }
    elsif ( $rate eq 'normal' ) {

        $weight = 2;
    }
    elsif ( $rate eq 'high' ) {

        $weight = 3;
    }

    return $weight || 1;
}

1;
