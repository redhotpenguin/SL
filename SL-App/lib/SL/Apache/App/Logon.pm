package SL::Apache::App::Logon;

use strict;
use warnings;

use Apache2::Const -compile => qw( NOT_FOUND SERVER_ERROR REDIRECT OK );
use Apache2::Log;
use Apache2::RequestIO;
use Apache2::RequestRec ();
use DBD::Pg qw(:pg_types);
use SL::Model;

use SL::App::Template ();
our $tmpl = SL::App::Template->template();

my $insert = <<INSERT;
INSERT INTO reg
( ip, email, firstname, lastname, street_addr, apt_suite, zipcode, phone, description, macaddr, referer, serial_number  ) 
VALUES 
( ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ? )
INSERT


sub handler {
    my $r = shift;

    if ( $r->method eq 'GET' ) {
        return &get($r);
    }
    elsif ( $r->method eq 'POST' ) {
        return &post($r);
    }
}

sub get {
    my $r = shift;

    # Grad anything in the connection pnotes
    my $c     = $r->connection;
    my $login = $c->pnotes('login');

    # build the template
    my $page;
    my $tmpl_ok = $tmpl->process( 'login.tmpl', $login, \$page );
    unless ($tmpl_ok) {
        $r->log->error( "Error processing template: " . $tmpl->error() );
        return Apache2::Const::SERVER_ERROR;
    }

    # send it to the client;
    $r->content_type('text/html');
    $r->print($page);
    return Apache2::Const::OK;
}

sub post {
    my $r = shift;

    my $req            = Apache2::Request->new($r);
    my %params         = $req->param;
    my %invalid_params = _validate( \%params );
    if ( keys %invalid_params ) {

        # Incomplete form, send em back
        my $c = $r->connection;
        $c->pnotes( login => \%invalid_params );
        $r->internal_redirect( $r->uri );
        return Apache2::Const::OK;
    }
    else {

        # Process the registration
		my $dbh = SL::Model->db_Main();
		my $sth = $dbh->prepare($insert);
		my $i = 0;
        $sth->bind_param( ++$i, $params{$_} ) for qw(
			ip 
			email 
			firstname 
			lastname 
			street_addr 
			apt_suite 
			zipcode 
			phone 
			description 
			macaddr
			referer
			serial_number );
        my $rv = $sth->execute;
        unless ($rv) {
            $r->log->error("$$ Could not save registration info");
            $dbh->rollback;
            return Apache2::Const::SERVER_ERROR;
        }
        else {
            $r->log->debug( "$$ registered ip  ", $params{'ip'} );
            $dbh->commit;
            $r->internal_redirect("/login/success");
            return Apache2::Const::OK;
        }
    }

}

1;
