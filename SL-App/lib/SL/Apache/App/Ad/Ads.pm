package SL::Apache::App::Ad::Ads;

use strict;
use warnings;

use Apache2::Const -compile => qw(OK SERVER_ERROR NOT_FOUND M_GET M_POST);
use Apache2::Log        ();
use Apache2::SubRequest ();
use Data::FormValidator ();
use Apache2::Request    ();
use Apache2::SubRequest ();

use base 'SL::Apache::App';

use SL::App::Template ();
our $tmpl = SL::App::Template->template();

# this specific template logic
use Data::Dumper;
use SL::Model;
use SL::Model::App;    # works for now

use DateTime;

sub shrink {
    my $string = shift;
    my $length = 25;
    return $string if ( length($string) - 3 ) < $length;
    return substr( $string, -length($string), $length ) . '...';
}

sub dispatch_index {
    my ($self, $r) = @_;

    my %tmpl_data = ( root => $r->pnotes('root'),
                       email => $r->user);
    my $output;
    my $ok = $tmpl->process('ad/ads/index.tmpl', \%tmpl_data, \$output);
    $ok ? return $self->ok($r, $output) 
        : return $self->error($r, "Template error: " . $tmpl->error());
}

=head1 METHODS

=over 4

=item C<dispatch_index>

This method serves of the master ad control panel for now

=back

=cut

sub dispatch_list {
    my ( $self, $r ) = @_;
    my %tmpl_data;

    # grab the ads
    my $count = 0;
    if ( $r->pnotes('root') ) {
        $tmpl_data{'root'} = 1;

        # root user gets all ads
        @{ $tmpl_data{'ads'} } =
          sort { $b->{active} <=> $a->{active} }
          sort { $b->{id} <=> $a->{id} }
          map  {
            {
                active  => $_->ad_id->active,
                  text  => shrink( $_->text ),
                  id    => $_->ad_sl_id,
                  cts   => $_->ad_id->cts,
                  email => $_->reg_id->email,
            }
          } SL::Model::App->resultset('AdSl')->all;
    }
    else {

        # thou art not root
        @{ $tmpl_data{'ads'} } =
          sort { $b->{active} <=> $a->{active} }
          sort { $b->{id} <=> $a->{id} }
          map  {
            {
                active  => $_->ad_id->active,
                  text  => shrink( $_->text ),
                  id    => $_->ad_sl_id,
                  cts   => $_->ad_id->cts,
                  email => $_->reg_id->email,
            }
          } SL::Model::App->resultset('AdSl')
          ->search( { reg_id => $r->pnotes( $r->user )->reg_id } );
    }
    $tmpl_data{'count'} = scalar( @{ $tmpl_data{'ads'} } );

    # set the status, if any
    my $req = Apache2::Request->new($r);
    if ( $req->param('status') ) {
        $tmpl_data{'status'}  = $req->param('status');
        $tmpl_data{'ad_text'} = $req->param('ad_text');
    }

    my $output;
    my $ok = $tmpl->process( 'ad/ads/list.tmpl', \%tmpl_data, \$output );
    $ok
      ? return $self->ok( $r, $output )
      : return $self->error( $r, "Template error: " . $tmpl->error() );
}

my %ad_profile = ( required => [qw( uri text active )], );

sub dispatch_edit {
    my ( $self, $r, $errors ) = @_;

    my $req = Apache2::Request->new($r);

    my ( %tmpl_data, $ad, $output, $link );
    if ( $req->param('id') ) {    # edit existing ad
        my %search;

        # restrict search params for nonroot
        if ( !$r->pnotes('root') ) {
            $search{reg_id} = $r->pnotes( $r->user )->reg_id;
        }

        $search{ad_sl_id} = $req->param('id');
        ($ad) = SL::Model::App->resultset('AdSl')->search( \%search );
        return Apache2::Const::NOT_FOUND unless $ad;
        $tmpl_data{'ad'} = {
            uri    => $ad->uri,
            id     => $ad->ad_sl_id,
            text   => $ad->text,
            active => $ad->ad_id->active
        };
    }

    if ( $r->method_number == Apache2::Const::M_GET ) {

        if ( keys %{$errors} ) {
            $tmpl_data{'errors'} = $errors;
        }

        my $ok = $tmpl->process( 'ad/ads/edit.tmpl', \%tmpl_data, \$output );
        $ok
          ? return $self->ok( $r, $output )
          : return $self->error( $r, "Template error: " . $tmpl->error() );
    }
    elsif ( $r->method_number == Apache2::Const::M_POST ) {

        my $results = Data::FormValidator->check( $req, \%ad_profile );
        my $errors = $self->SUPER::_results_to_errors($results);
        $r->method_number(Apache2::Const::M_GET);
        return $self->dispatch_edit( $r, $errors );
    }

    my ( $status, $base_ad );
    if  ( not defined $ad ) {
        # make the base ad first
        $base_ad = SL::Model::App->resultset('Ad')->new( { active => 't' } );
        $base_ad->insert();

        # make the sl_ad
        $ad = SL::Model::App->resultset('AdSl')->new(
            {
                ad_id  => $base_ad->ad_id,
                text   => $req->param('text'),
                uri    => $req->param('uri'),
                reg_id => $r->pnotes( $r->user )->reg_id,
            }
        );
        $ad->insert();
        $status = 'added';
        $base_ad->update;
        $ad->update;
    }
    else {
        $ad->ad_id->active( $req->param('active') );
        $ad->text( $req->param('text') );
        $ad->uri( $req->param('uri') );
        $status = 'updated';
        $ad->ad_id->update;
        $ad->update;
    }

    $r->method_number(Apache2::Const::M_GET);
    $r->internal_redirect(
        "/app/ad/list/?status=$status&ad_text=" . $ad->text );
    return Apache2::Const::OK;
}

1;
