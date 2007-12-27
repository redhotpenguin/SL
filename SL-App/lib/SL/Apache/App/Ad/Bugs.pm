package SL::Apache::App::Ad::Bugs;

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

sub dispatch_index {
    my ( $self, $r ) = @_;

    my %tmpl_data = (
        root  => $r->pnotes('root'),
        email => $r->user
    );
    my $output;
    my $ok = $tmpl->process( 'ad/bugs/index.tmpl', \%tmpl_data, \$output );
    $ok
      ? return $self->ok( $r, $output )
      : return $self->error( $r, "Template error: " . $tmpl->error() );
}

sub dispatch_edit {
    my ( $self, $r, $args_ref ) = @_;

    my $req = $args_ref->{req} || Apache2::Request->new($r);
    my $reg = $r->pnotes( $r->user );
    my ( $bug, $output, $link );
    if ( $req->param('id') ) {    # edit existing ad group
        ($bug) = SL::Model::App->resultset('Bug')->search(
            {
                reg_id => $r->pnotes( $r->user )->reg_id,
                bug_id => $req->param('id'),
            }
        );

        return Apache2::Const::NOT_FOUND unless $bug;
    }

    # get the bugs
    if ( $r->method_number == Apache2::Const::M_GET ) {
        my %tmpl_data = (
            root   => $r->pnotes('root'),
            reg    => $reg,
            bug    => $bug,
            errors => $args_ref->{errors},
            status => $args_ref->{status},
            req    => $req,
        );

        my $ok = $tmpl->process( 'ad/bugs/edit.tmpl', \%tmpl_data, \$output );
        $ok
          ? return $self->ok( $r, $output )
          : return $self->error( $r, "Template error: " . $tmpl->error() );
    }
    elsif ( $r->method_number == Apache2::Const::M_POST ) {
        $r->method_number(Apache2::Const::M_GET);

        # validate input
        my %bug_profile = (
            required           => [qw( name link_href image_href active )],
            constraint_methods => {
                link_href  => SL::Apache::App::valid_link(),
                image_href => SL::Apache::App::valid_link(),
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

    unless ( $req->param('id') ) {

        # create a new bug
        $bug = SL::Model::App->resultset('Bug')->create( { active => 't' } );
    }

    # add arguments
    foreach my $param qw( name link_href image_href bug_id active ) {
        $bug->$param( $req->param($param) );
    }
    $bug->reg_id( $reg->reg_id );
    $bug->update;

    my $status = $req->param('id') ? 'updated' : 'created';
    $r->pnotes('session')->{msg} =
      sprintf( "Bug '%s' was %s", $bug->name, $status );

    $r->internal_redirect("/app/ad/bugs/list");
    return Apache2::Const::OK;
}

sub dispatch_list {
    my ( $self, $r, $args_ref ) = @_;

    my @bugs =
      SL::Model::App->resultset('Bug')
      ->search( { reg_id => $r->pnotes( $r->user )->reg_id } );

    my @default_bugs = SL::Model::App->resultset('Bug')
	  ->search({ is_default => 1 });

    my %tmpl_data = (
        bugs    => \@bugs,
		default_bugs => \@default_bugs,
        count   => scalar(@bugs),
        root    => $r->pnotes('root'),
        session => $r->pnotes('session'),
    );

    my $output;
    my $ok = $tmpl->process( 'ad/bugs/list.tmpl', \%tmpl_data, \$output );
    $ok
      ? return $self->ok( $r, $output )
      : return $self->error( $r, "Template error: " . $tmpl->error() );
}

1;
