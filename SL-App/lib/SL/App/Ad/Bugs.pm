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

our $Tmpl = SL::App::Template->template();

sub dispatch_index {
    my ( $self, $r ) = @_;

    my $output;
    $Tmpl->process( 'ad/bugs/index.tmpl', {}, \$output, $r )
      || return $self->error( $r, $Tmpl->error );
    return $self->ok( $r, $output );
}

sub dispatch_add {
    my ( $self, $r ) = @_;

    my $req = Apache2::Request->new($r);
    my $reg = $r->pnotes( $r->user );

    if ( $r->method_number == Apache2::Const::M_GET ) {

        my $ad_zone = SL::Model::App->resultset('AdZone')->create(
            {
                name       => 'New Branding Image',
                account_id => $reg->account_id,
                reg_id     => $reg->reg_id,
                ad_size_id => 20, # IAB Button 1
                code       => '',
                active     => 1,
                is_default => 0,
                image_href => ' ',
                link_href => ' ',
            }
        );
        return Apache2::Const::NOT_FOUND unless $ad_zone;
        $ad_zone->update;


        return $self->dispatch_edit( $r, { req => $req }, $ad_zone );

    }

}



sub dispatch_edit {
    my ( $self, $r, $args_ref, $ad_zone_obj ) = @_;

    my $req = $args_ref->{req} || Apache2::Request->new($r);

    my $reg = $r->pnotes( $r->user );

    my $bug;
    if (my $id = $req->param('id')) {

      $bug = $reg->get_ad_zone( $id );

    } elsif ($ad_zone_obj) {

      $bug = $ad_zone_obj;

    }

    return Apache2::Const::NOT_FOUND unless $bug;

    # get the bugs
    my $width;
    if ( $r->method_number == Apache2::Const::M_GET ) {

        my %tmpl_data = (
            ad_zone  => $bug,
            errors   => $args_ref->{errors},
            image_err => $args_ref->{image_err},
            req      => $req,
        );

        my $output;
        $Tmpl->process( 'ad/bugs/edit.tmpl', \%tmpl_data, \$output, $r )
          || return $self->error( $r, $Tmpl->error );
        return $self->ok( $r, $output );
    }
    elsif ( $r->method_number == Apache2::Const::M_POST ) {
        $r->method_number(Apache2::Const::M_GET);

        # validate input
        my @required = qw( name image_href link_href active is_default id);
        my $constraints = {
                image_href => $self->valid_branding_image(),
                link_href  => $self->valid_link(),
            };

        my %profile = ( required => \@required,
                        constraint_methods => $constraints);


        my $results = Data::FormValidator->check( $req, \%profile );

        if ( $results->has_missing or $results->has_invalid ) {
            my $errors = $self->SUPER::_results_to_errors($results);

            $r->log->debug("results are " . Data::Dumper::Dumper($results)) if DEBUG;

            return $self->dispatch_edit(
                $r,
                {
                    image_err => $results->{image_err},
                    errors => $errors,
                    req    => $req
                }
            );
        }

        $width = $results->{valid}->{width};
    }


    if ( $width == 200 ) {

        # SLN Button 1
        $bug->ad_size_id(22);

    }
    elsif ( $width == 120 ) {

        # IAB Button 1
        $bug->ad_size_id(20);
    }

    # calculate the weight
    my $weight = $self->display_weight( $req->param('display_rate') );


    # add arguments
    foreach my $param qw( name link_href image_href active is_default ) {
        $bug->$param( $req->param($param) );
    }
    $bug->weight($weight);
    $bug->mts( DateTime::Format::Pg->format_datetime(
                       DateTime->now(time_zone => 'local')));
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
    $self->format_adzone_list(\@bugs);

    my %tmpl_data = (
        ad_zones => \@bugs,
        count    => scalar(@bugs),
    );

    my $output;
    $Tmpl->process( 'ad/bugs/list.tmpl', \%tmpl_data, \$output, $r )
      || return $self->error( $r, $Tmpl->error );
    return $self->ok( $r, $output );
}


1;
