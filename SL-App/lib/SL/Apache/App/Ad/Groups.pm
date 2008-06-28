package SL::Apache::App::Ad::Groups;

use strict;
use warnings;

use Apache2::Const -compile =>
  qw(OK SERVER_ERROR NOT_FOUND REDIRECT M_GET M_POST);
use Apache2::Log        ();
use Apache2::SubRequest ();
use Data::FormValidator ();
use Apache2::Request    ();
use Apache2::SubRequest ();

use base 'SL::Apache::App';

use SL::Model;
use SL::Model::App;
use SL::App::Template ();

our $TMPL = SL::App::Template->template();

use constant DEBUG => $ENV{SL_DEBUG} || 0;
require Data::Dumper if DEBUG;

sub dispatch_index {
    my ( $self, $r ) = @_;

    my $output;
    my $ok = $TMPL->process( 'ad/groups/index.tmpl', {}, \$output, $r );

    return $self->ok( $r, $output ) if $ok;
    return $self->error( $r, "Template error: " . $TMPL->error() );
}

sub dispatch_edit {
    my ( $self, $r, $args_ref ) = @_;

    my $req = $args_ref->{req} || Apache2::Request->new($r);
    my $reg = $r->pnotes( $r->user );

    my $ad_zone;

    if ( my $ad_zone_id = $req->param('id') ) {

        # edit existing ad zone
        $ad_zone = $reg->get_ad_zone($ad_zone_id);
        return Apache2::Const::NOT_FOUND unless $ad_zone;
    }

    if ( $r->method_number == Apache2::Const::M_GET ) {
        my %tmpl_data = (
            ad_sizes   => [ SL::Model::App->resultset('AdSize')->all ],
            ad_zone    => $ad_zone,
            errors     => $args_ref->{errors},
            req        => $req,
            bug_list_1 => [
                SL::Model::App->resultset('Bug')->search(
                    {
                        account_id => $reg->account_id->account_id,
                        ad_size_id => 1
                    }
                )
            ],
            bug_list_2 => [
                SL::Model::App->resultset('Bug')->search(
                    {
                        account_id => $reg->account_id->account_id,
                        ad_size_id => 2
                    }
                )
            ],
            bug_list_3 => [
                SL::Model::App->resultset('Bug')->search(
                    {
                        account_id => $reg->account_id->account_id,
                        ad_size_id => 3
                    }
                )
            ],
        );

        my $output;
        my $ok =
          $TMPL->process( 'ad/groups/edit.tmpl', \%tmpl_data, \$output, $r );

        return $self->ok( $r, $output ) if $ok;
        return $self->error( $r, "Template error: " . $TMPL->error() );
    }
    elsif ( $r->method_number == Apache2::Const::M_POST ) {

        # reset the method
        $r->method_number(Apache2::Const::M_GET);

        # validate input
        my %profile = ( required => [qw( name active ad_size_id code )], );

        my $results = Data::FormValidator->check( $req, \%profile );

        if ( $results->has_missing or $results->has_invalid ) {
            my $errors = $self->SUPER::_results_to_errors($results);

            return $self->dispatch_edit(
                $r,
                {
                    errors => $errors,
                    req    => $req
                }
            );
        }
    }

    unless ( $req->param('id') ) {

        # create a new ad zone
        $ad_zone = SL::Model::App->resultset('AdZone')->create(
            {
                reg_id     => $reg->reg_id,
                account_id => $reg->account_id->account_id
            }
        );
    }

    # add arguments
    foreach my $param qw( name code ad_size_id bug_id ) {
        $ad_zone->$param( $req->param($param) );
    }

    $ad_zone->update;

    # done with argument processing
    my $status = $req->param('id') ? 'updated' : 'created';
    $r->pnotes('session')->{msg} =
      sprintf( "Ad Zone '%s' was %s", $ad_zone->name, $status );

    $r->headers_out->set(
        Location => $r->construct_url('/app/ad/groups/list') );
    return Apache2::Const::REDIRECT;
}

sub dispatch_list {
    my ( $self, $r, $args_ref ) = @_;

    my $reg = $r->pnotes( $r->user );

    # get the ad zones this user has access to
    my @ad_zones = $reg->get_ad_zones;

    $r->log->debug( "ad zones: " . Data::Dumper::Dumper( \@ad_zones ) )
      if DEBUG;

    my %tmpl_data = (
        session  => $r->pnotes('session'),
        ad_zones => \@ad_zones,
        count    => scalar(@ad_zones),
    );

    my $output;
    my $ok = $TMPL->process( 'ad/groups/list.tmpl', \%tmpl_data, \$output, $r );

    return $self->ok( $r, $output ) if $ok;
    return $self->error( $r, "Template error: " . $TMPL->error() );
}

1;
