package SL::Apache::App::Ad::Bugs;

use strict;
use warnings;

use Apache2::Const -compile => qw(OK SERVER_ERROR NOT_FOUND M_GET M_POST);
use Apache2::Log        ();
use Apache2::SubRequest ();
use Apache2::Request    ();
use Apache2::SubRequest ();

use Data::FormValidator ();

use base 'SL::Apache::App';
use SL::App::Template ();
use SL::Model;
use SL::Model::App;    # works for now

use constant DEBUG => $ENV{SL_DEBUG} || 0;

require Data::Dumper if DEBUG;

our $TMPL = SL::App::Template->template();

sub dispatch_index {
    my ( $self, $r ) = @_;

    my $output;
    my $ok = $TMPL->process( 'ad/bugs/index.tmpl', {}, \$output, $r );

    return $self->ok( $r, $output ) if $ok;
    return $self->error( $r, "Template error: " . $TMPL->error() );
}

sub dispatch_edit {
    my ( $self, $r, $args_ref ) = @_;

    my $req = $args_ref->{req} || Apache2::Request->new($r);

    my $reg = $r->pnotes( $r->user );

    my ( $bug, $output, $link );
    if ( $req->param('id') ) {    # edit existing ad group
        ($bug) = SL::Model::App->resultset('Bug')->search(
            {
                account_id => $r->pnotes( $r->user )->account_id->account_id,
                bug_id => $req->param('id'),
            }
        );

        return Apache2::Const::NOT_FOUND unless $bug;
    }

    # get the bugs
    if ( $r->method_number == Apache2::Const::M_GET ) {

        my %tmpl_data = (
            bug    => $bug,
            errors => $args_ref->{errors},
            req    => $req,
            ad_sizes => [ sort { $a->grouping <=> $b->grouping } 
				SL::Model::App->resultset('AdSize')->all ],
        );

        my $ok =
          $TMPL->process( 'ad/bugs/edit.tmpl', \%tmpl_data, \$output, $r );

        return $self->ok( $r, $output ) if $ok;
        return $self->error( $r, "Template error: " . $TMPL->error() );
    }
    elsif ( $r->method_number == Apache2::Const::M_POST ) {
        $r->method_number(Apache2::Const::M_GET);

        # validate input
        my %bug_profile = (
            required           => [qw( ad_size_id link_href image_href )],
            constraint_methods => {

                link_href  => SL::Apache::App::valid_link(),
                image_href => [
                    SL::Apache::App::valid_link(),
                    SL::Apache::App::image_zone(
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

    unless ($bug) {

        # create a new bug
        $bug =
          SL::Model::App->resultset('Bug')
          ->new( { ad_size_id => $req->param('ad_size_id') } );
    }

    # add arguments
    foreach my $param qw( link_href image_href ad_size_id ) {
        $bug->$param( $req->param($param) );
    }
    $bug->account_id( $reg->account_id->account_id );

    $req->param('id') ? $bug->update : $bug->insert;

    my $status = $req->param('id') ? 'updated' : 'created';
    $r->pnotes('session')->{msg} = "Branding image $status successfully";

    $r->headers_out->set( Location => $r->construct_url('/app/ad/bugs/list') );
    return Apache2::Const::REDIRECT;
}

sub dispatch_list {
    my ( $self, $r, $args_ref ) = @_;

    my $reg = $r->pnotes( $r->user );

    my @bugs =
      SL::Model::App->resultset('Bug')
      ->search( { account_id => $reg->account_id->account_id } );

    my $msg = delete $r->pnotes('session')->{msg};

    my %tmpl_data = (
        bugs    => \@bugs,
        count   => scalar(@bugs),
        session => $r->pnotes('session'),
        msg => $msg,
    );

    my $output;
    my $ok = $TMPL->process( 'ad/bugs/list.tmpl', \%tmpl_data, \$output, $r );

    return $self->ok( $r, $output ) if $ok;
    return $self->error( $r, "Template error: " . $TMPL->error() );
}

1;
