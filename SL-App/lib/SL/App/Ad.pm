package SL::App::Ad;

use strict;
use warnings;

use Apache2::Const -compile => qw(OK SERVER_ERROR NOT_FOUND M_GET M_POST);
use Apache2::Log        ();
use Apache2::SubRequest ();
use Data::FormValidator ();
use Apache2::Request    ();
use Apache2::SubRequest ();

use base 'SL::App';

use SL::App::Template ();
our $tmpl = SL::App::Template->template();

# this specific template logic
use Data::Dumper;
use SL::Model;
use SL::Model::App;    # works for now

sub dispatch_index {
    my ( $self, $r ) = @_;

    my $output;
    $tmpl->process( 'ad/index.tmpl', {}, \$output, $r )
      || return $self->error( $r, $tmpl->error );
    return $self->ok( $r, $output );
}


sub dispatch_deactivate {
    my ( $class, $r, $args_ref ) = @_;

    my $reg = $r->pnotes( $r->user );
    my $req = Apache2::Request->new($r);

    my $id = $req->param('id');

    my ($ad_zone) = SL::Model::App->resultset('AdZone')->search(
        {
            account_id => $reg->account_id,
            ad_zone_id  => $id,
            active     => 't',
        }
    );

    return Apache2::Const::NOT_FOUND unless $ad_zone;

    $ad_zone->active(0);
    $ad_zone->update;

    $r->pnotes('session')->{msg} = sprintf( "Ad '%s' was deleted", $ad_zone->name );
    $r->headers_out->set(
        Location => $r->headers_in->{'referer'} );
    return Apache2::Const::REDIRECT;
}




1;
