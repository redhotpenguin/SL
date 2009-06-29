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

use constant LEADERBOARD_BUG_SIZE => 2;

our $TMPL = SL::App::Template->template();

sub dispatch_index {
    my ( $self, $r ) = @_;

    my $output;
    $TMPL->process( 'ad/bugs/index.tmpl', {}, \$output, $r )
      || return $self->error( $r, $TMPL->error );
    return $self->ok( $r, $output );
}

sub dispatch_edit {
    my ( $self, $r, $args_ref ) = @_;

    my $req = $args_ref->{req} || Apache2::Request->new($r);

    my $reg = $r->pnotes( $r->user );

    my ($bug) = SL::Model::App->resultset('AdZone')->search(
        {
            account_id => $reg->account->account_id,
            ad_zone_id => $req->param('id'),
        }
    );

    return Apache2::Const::NOT_FOUND unless $bug;

    # get the bugs
    if ( $r->method_number == Apache2::Const::M_GET ) {

        my %tmpl_data = (
            ad_zone  => $bug,
            errors   => $args_ref->{errors},
            req      => $req,
        );

        my $output;
        $TMPL->process( 'ad/bugs/edit.tmpl', \%tmpl_data, \$output, $r )
          || return $self->error( $r, $TMPL->error );
        return $self->ok( $r, $output );
    }
    elsif ( $r->method_number == Apache2::Const::M_POST ) {
        $r->method_number(Apache2::Const::M_GET);

        # validate input
        my @required = qw( name image_href link_href);
        my $constraints = {
                image_href => $self->valid_link(),
                link_href  => $self->valid_link(),
            };

        my %profile = ( required => \@required, constraint_methods => $constraints);


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


    # add arguments
    foreach my $param qw( name link_href image_href active is_default ) {
        $bug->$param( $req->param($param) );
    }
    $bug->ad_size_id( LEADERBOARD_BUG_SIZE );
    $bug->bug_id( 1 );
    $bug->mts( DateTime::Format::Pg->format_datetime( DateTime->now ));
    $bug->update;


    $r->pnotes('session')->{msg} = sprintf("Branding Image '%s' updated successfully", $bug->name);
    $r->headers_out->set( Location => $r->construct_url('/app/ad/bugs/list') );
    return Apache2::Const::REDIRECT;
}

sub dispatch_list {
    my ( $self, $r, $args_ref ) = @_;

    my $reg = $r->pnotes( $r->user );

    my @bugs = sort { $b->mts cmp $a->mts } $reg->get_branding_zones;

    # format the time
    $_->mts( $self->sldatetime( $_->mts ) ) for @bugs;

    my %tmpl_data = (
        ad_zones => \@bugs,
        count    => scalar(@bugs),
    );

    my $output;
    $TMPL->process( 'ad/bugs/list.tmpl', \%tmpl_data, \$output, $r )
      || return $self->error( $r, $TMPL->error );
    return $self->ok( $r, $output );
}

1;
