package SL::App::Ad::Msg;

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

our $Tmpl = SL::App::Template->template;

sub dispatch_index {
    my ( $self, $r, $args_ref ) = @_;

    my $req = $args_ref->{req} || Apache2::Request->new($r);
    my $reg = $r->pnotes( $r->user );

    my $text_message = $req->param('text_message');

    ############################################
    # make sure we have a text message entry
    my %args = (
        name       => '_message_bar',
        ad_size_id => 23,
        hidden     => 1,
        account_id => $reg->account_id,
    );

    my ($ad_zone) = SL::Model::App->resultset('AdZone')->search( \%args );
    unless ($ad_zone) {

        # create it
        $ad_zone =
          SL::Model::App->resultset('AdZone')
          ->create( { %args, reg_id => $reg->reg_id, code => '' } );
        $ad_zone->update;
    }

    ######################################################
    # grab the branding image
    my %bug_args = (
        ad_size_id => 24,
        account_id => $reg->account_id,
    );

    my ($bug) = SL::Model::App->resultset('Bug')->search( \%bug_args );

    unless ($bug) {

        # create it
        $bug = SL::Model::App->resultset('Bug')->create(
            {
                %bug_args,
                image_href =>
                  'http://s1.slwifi.com/images/ads/sln/micro_bug.gif',
                link_href => 'http://www.silverliningnetworks.com/',
            }
        );
        $bug->update;
    }

    if ( $r->method_number == Apache2::Const::M_GET ) {

        my %tmpl_data = (
            ad_zone => $ad_zone,
            bug     => $bug,
            errors  => $args_ref->{errors},
            req     => $req,
        );

        my $output;
        $Tmpl->process( 'ad/msg/index.tmpl', \%tmpl_data, \$output, $r )
          || return $self->error( $r, $Tmpl->error );
        return $self->ok( $r, $output );

    }
    elsif ( $r->method_number == Apache2::Const::M_POST ) {

        $r->method_number(Apache2::Const::M_GET);

        my %profile = (
            required           => [qw( text_message )],
            optional           => [qw( sweep )],
            constraint_methods => { text_message => $self->valid_msg(), }
        );

        my $results = Data::FormValidator->check( $req, \%profile );

        if ( $results->has_missing or $results->has_invalid ) {
            my $errors = $self->SUPER::_results_to_errors($results);

            return $self->dispatch_index(
                $r,
                {
                    errors => $errors,
                    req    => $req
                }
            );
        }
    }

    # text message is valid
    $reg->account->text_message($text_message);
    $reg->account->update;

    # update the ad zone
    $ad_zone->code($text_message);
    $ad_zone->reg_id( $reg->reg_id );
    $ad_zone->update;

    # update the branding image if this is not a free account
    if ( $reg->account->plan ne 'free' ) {

        $bug->image_href( $req->param('image_href') );
        $bug->link_href( $req->param('link_href') );
        $bug->update;
    }

    if ( !$req->param('sweep') ) {

        $r->pnotes('session')->{msg} = "Message Bar updated to '$text_message'";

    }
    else {

        # sweep

        my @routers =
          SL::Model::App->resultset('Router')
          ->search(
            { active => 't', account_id => $reg->account->account_id } );

        foreach my $router (@routers) {

            SL::Model::App->resultset('RouterAdZone')
              ->search( { router_id => $router->router_id } )->delete_all;

            SL::Model::App->resultset('RouterAdZone')->find_or_create(
                {
                    router_id  => $router->router_id,
                    ad_zone_id => $ad_zone->ad_zone_id,
                }
            );

            SL::Model::App->resultset('RouterAdZone')->find_or_create(
                {
                    router_id  => $router->router_id,
                    ad_zone_id => $bug->ad_zone_id,
                }
            );

        }

        $r->pnotes('session')->{msg} =
          sprintf( "Message Bar updated to '%s', assigned to %d devices",
            $text_message, scalar(@routers) );
    }

    $r->headers_out->set( Location => $r->headers_in->{'referer'} );
    return Apache2::Const::REDIRECT;

}

sub valid_msg {
    my $self = shift;

    return sub {
        my $dfv = shift;
        my $val = $dfv->get_current_constraint_value;

        return if length($val) > 300;
        return $val;
      }
}

1;
