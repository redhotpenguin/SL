package SL::App::Ad::Bugs;

use strict;
use warnings;

use Apache2::Const -compile => qw(OK SERVER_ERROR NOT_FOUND M_GET M_POST);
use Apache2::Log        ();
use Apache2::SubRequest ();
use Apache2::Request    ();
use Apache2::SubRequest ();

use Data::FormValidator ();

use base 'SL::App';
use SL::App::Template ();
use SL::Model;
use SL::Model::App;    # works for now
use Data::Dumper;

use constant DEBUG => $ENV{SL_DEBUG} || 0;

our $TMPL = SL::App::Template->template();

sub dispatch_index {
    my ( $self, $r ) = @_;

    my $output;
    $TMPL->process( 'ad/bugs/index.tmpl', {}, \$output, $r ) ||
      return $self->error( $r, $TMPL->error );
    return $self->ok( $r, $output );
}

sub dispatch_edit {
    my ( $self, $r, $args_ref ) = @_;

    my $req = $args_ref->{req} || Apache2::Request->new($r);

    my $reg = $r->pnotes( $r->user );

    my ( $output, $link );
    my ($bug) = SL::Model::App->resultset('AdZone')->search(
            {
                account_id => $reg->account->account_id,
                ad_zone_id => $req->param('id'),
            }
    );


    return Apache2::Const::NOT_FOUND unless $bug;

    my @ad_sizes = sort { $a->grouping <=> $b->grouping }
                     $reg->get_branding_sizes;

    # get the bugs
    if ( $r->method_number == Apache2::Const::M_GET ) {

        my %tmpl_data = (
            ad_zone    => $bug,
            errors => $args_ref->{errors},
            req    => $req,
            ad_sizes => \@ad_sizes,
        );

        $TMPL->process( 'ad/bugs/edit.tmpl', \%tmpl_data, \$output, $r ) ||
          return $self->error( $r, $TMPL->error);
        return $self->ok( $r, $output );
    }
    elsif ( $r->method_number == Apache2::Const::M_POST ) {
        $r->method_number(Apache2::Const::M_GET);

        # validate input
        my %bug_profile = (
            required  => [qw( ad_size_id link_href image_href active )],
            constraint_methods => {
                link_href  => SL::App::valid_link(),
                image_href => [
                    SL::App::valid_link(),
                    SL::App::image_zone(
                        { fields => [ 'image_href', 'ad_size_id' ] }
                    ),
                ],
            }
        );

        my $results = Data::FormValidator->check( $req, \%bug_profile );

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

    # add arguments
    foreach my $param qw( link_href image_href ad_size_id active ) {
        $bug->$param( $req->param($param) );
    }
    $bug->account_id( $reg->account_id );

    $req->param('id') ? $bug->update : $bug->insert;

    my $status = $req->param('id') ? 'updated' : 'created';
    $r->pnotes('session')->{msg} = "Branding image $status successfully";

    $r->headers_out->set( Location => $r->construct_url('/app/ad/bugs/list') );
    return Apache2::Const::REDIRECT;
}

sub dispatch_list {
    my ( $self, $r, $args_ref ) = @_;

    my $reg = $r->pnotes( $r->user );

    my @bugs = sort { $b->mts cmp $a->mts }
               sort { $a->grouping cmp $b->grouping }
                 $reg->get_branding_zones;

    my $msg = delete $r->pnotes('session')->{msg};

    my %tmpl_data = (
        ad_zones    => \@bugs,
        count   => scalar(@bugs),
        session => $r->pnotes('session'),
        msg => $msg,
    );

    my $output;
    $TMPL->process( 'ad/bugs/list.tmpl', \%tmpl_data, \$output, $r ) ||
          return $self->error( $r, $TMPL->error );
    return $self->ok( $r, $output );

}

1;
