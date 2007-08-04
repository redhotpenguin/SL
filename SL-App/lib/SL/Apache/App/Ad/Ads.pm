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

use SL::Config;
our $CONFIG = SL::Config->new;

use SL::App::Template ();
our $tmpl = SL::App::Template->template();

# this specific template logic
use Data::Dumper;
use SL::Model;
use SL::Model::App;    # works for now

sub shrink {
    my $string = shift;
    my $length = 60;
    return $string if ( length($string) - 3 ) < $length;
    return substr( $string, -length($string), $length ) . '...';
}

sub dispatch_index {
    my ( $self, $r ) = @_;

    my %tmpl_data = (
        root  => $r->pnotes('root'),
        email => $r->user
    );
    my $output;
    my $ok = $tmpl->process( 'ad/ads/index.tmpl', \%tmpl_data, \$output );
    $ok
      ? return $self->ok( $r, $output )
      : return $self->error( $r, "Template error: " . $tmpl->error() );
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

    $tmpl_data{session} = $r->pnotes('session');
    my $output;
    my $ok = $tmpl->process( 'ad/ads/list.tmpl', \%tmpl_data, \$output );
    $ok
      ? return $self->ok( $r, $output )
      : return $self->error( $r, "Template error: " . $tmpl->error() );
}

sub dispatch_edit {
    my ( $self, $r, $args_ref ) = @_;

    my $req = $args_ref->{req} || Apache2::Request->new($r);

    my ( %tmpl_data, $ad, $output, $link, @reg__ad_groups );
    if ( $req->param('id') ) {    # edit existing ad
        my %search;

        # restrict search params for nonroot
        if ( !$r->pnotes('root') ) {
            $search{reg_id} = $r->pnotes( $r->user )->reg_id;
        }

        $search{ad_sl_id} = $req->param('id');
        ($ad) = SL::Model::App->resultset('AdSl')->search( \%search );
        return Apache2::Const::NOT_FOUND unless $ad;

        # get the ad groups for this ad
        my @ad__ad_groups = SL::Model::App->resultset('AdAdGroup')->search({
             ad_id => $ad->ad_id->ad_id });
        my %ad_group_hash = map { $_->ad_group_id->ad_group_id => 1 } @ad__ad_groups;

        # get the allowed ad groups for this user, and mark the ones selected for this ad
        @reg__ad_groups = SL::Model::App->resultset('RegAdGroup')->search({
             reg_id => $r->pnotes($r->user)->reg_id });
        foreach my $reg__ad_group ( @reg__ad_groups ) {
          if (exists $ad_group_hash{$reg__ad_group->ad_group_id->ad_group_id}) {
            $reg__ad_group->{selected} = 1;
          }
        }

        $tmpl_data{'ad'} = {
            uri    => $ad->uri,
            id     => $ad->ad_sl_id,
            text   => $ad->text,
            active => $ad->ad_id->active
        };
    }

    if ( $r->method_number == Apache2::Const::M_GET ) {
        %tmpl_data = (
            ad => $ad,
            reg__ad_groups => \@reg__ad_groups,
            session => $r->pnotes('session'),
            root    => $r->pnotes('root'),
            req     => $req,
            errors => $args_ref->{errors},
        );
        my $ok = $tmpl->process( 'ad/ads/edit.tmpl', \%tmpl_data, \$output );
        $ok
          ? return $self->ok( $r, $output )
          : return $self->error( $r, "Template error: " . $tmpl->error() );
    }
    elsif ( $r->method_number == Apache2::Const::M_POST ) {

        $r->method_number(Apache2::Const::M_GET);
        my %ad_profile = ( required => [qw( uri text active )], );
        my $results = Data::FormValidator->check( $req, \%ad_profile );

        if ($results->has_missing or $results->has_invalid) {
          my $errors = $self->SUPER::_results_to_errors($results);
          return $self->dispatch_edit( $r, { errors => $errors, req => $req } );
        }
    }

    my ($base_ad, $action);
    unless ($ad ) {

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
        $base_ad->update;
        $ad->update;
        $action = 'added';
    }
    else {
        $ad->ad_id->active( $req->param('active') );
        foreach my $param qw( text uri ) {
          $ad->$param( $req->param($param) );
        }
        $ad->ad_id->update;
        $ad->update;
        $action = 'updated';
    }

    # handle the ad group associations
    # delete the old ones first
    SL::Model::App-resultset('AdAdGroup')->search({
          ad_id => $ad->ad_id })->delete_all;
    foreach my $ad_group_id ( $req->param('ad_group') ) {
      SL::Model::App->resultset('AdAdGroup')->find_or_create({
           ad_id => $ad->ad_id,
           ad_group_id => $ad_group_id, });
    }

    # set session msg
    $r->pnotes('session')->{msg} =
      sprintf( "Ad '%s' has been %s", $req->param('text'), $action );

    # set session msg
    $r->internal_redirect( $CONFIG->sl_app_base_uri . "/app/ad/ads/list" );
    return Apache2::Const::OK;
}

1;
