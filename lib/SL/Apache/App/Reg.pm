package SL::Apache::App::Reg;

use strict;
use warnings;

use Apache2::Request    ();
use Apache2::RequestRec ();
use Apache2::Log        ();
use Apache2::Const -compile => qw( OK SERVER_ERROR );
use Apache2::Connection     ();
use Apache2::ConnectionUtil ();
use Template;

my $tmpl;

BEGIN {
    my $tmpl_root = $ENV{SL_ROOT} . '/proxyserver/tmpl';
    my %config = ( INCLUDE_PATH => $tmpl_root );    # or list ref
    $tmpl = Template->new( \%config ) || die $Template::ERROR;
    require Data::Dumper;
}

sub handler {
    my $r = shift;

    $r->log->debug("$$ serving registration page");

    # registration form
    if ( $r->method eq 'GET' ) {
        $r->log->debug("$$ handling POST request for reg");

        # print the registration form
        return &serve_reg_form($r);

    }
    elsif ( $r->method eq 'POST' ) {
        $r->log->debug("$$ handling POST request for reg");

        my $dbh = SL::Model->db_Main();
        unless ($dbh) {
            $r->log->error("$$ dbi connection failed");
            return Apache2::Const::SERVER_ERROR;
        }
        my ( $row, $code ) = process_reg_form( $r, $dbh );
        if ( !$row ) {

            # invalid activation code, no rows returned form db
            $r->log->info(
                sprintf( "$$ Invalid activation code %s used", $code ) );
            return &serve_reg_form( $r, { code => $code, fail => 1 } );
        }
        elsif ( $row && ( $row->[0] == 0 ) ) {

            # activation code is valid and has not been used
            $r->log->info(
                sprintf( "Activating code %s used for activation", $code ) );
            return &activate( $r,
                { dbh => $dbh, code => $code, active => $row->[0] } );
        }
        elsif ( $row && ( $row->[0] > 0 ) ) {

            # this one has been registered already
            $r->log->info(
                sprintf(
                    "Code %s already used for ip %s, this is activation #%d",
                    $code, $row->[1], $row->[0] + 1
                )
            );
            return &activate( $r,
                { dbh => $dbh, code => $code, active => $row->[0] } );
        }

    }
}

sub activate {
    my ( $r, $args ) = @_;

    my $dbh    = $args->{dbh};
    my $code   = $args->{code};
    my $active = $args->{active};
    my $sql    = qq{update reg set active = ?, ip = ? where code = ?};
    my $sth    = $dbh->prepare($sql);
    $sth->bind_param( 1, ++$active );
    $sth->bind_param( 2, $r->connection->remote_ip );
    $sth->bind_param( 3, $code );
    my $rv = $sth->execute;

    unless ($rv) {
        $dbh->rollback;
        $r->log->error(
            "$$ Failed to execute query $sql for code $code, active $active");
        return Apache2::Const::SERVER_ERROR;
    }
    else {
        $dbh->commit;
        $r->log->info(
            sprintf(
                "$$ Activated code %s activation number %d",
                $code, $active
            )
        );
        my $dest = $r->connection->pnotes('dest');
        my $output;
        my $ok =
          $tmpl->process( 'activated.tmpl', { dest => $dest }, \$output );
        unless ($ok) {
            $r->log->error(
                "$$ problem processing template activated: " . $tmpl->error() );
            return Apache2::Const::SERVER_ERROR;
        }
        $r->content_type('text/html');
        $r->print($output);
        return Apache2::Const::OK;
    }
}

sub serve_reg_form {
    my ( $r, $vars ) = @_;

    my $output;
    my $ok = $tmpl->process( 'reg.tmpl', $vars, \$output );

    # handle error/success
    if ($ok) {
        $r->log->debug("$$ Serving login form");
        $r->content_type('text/html');
        $r->print($output);
        return Apache2::Const::OK;
    }
    elsif ( !$ok ) {
        $r->log->error(
            "$$ problem serving login form, error: " . $tmpl->error() );
        return Apache2::Const::SERVER_ERROR;
    }
}

sub process_reg_form {
    my ( $r, $dbh ) = @_;
    my $req  = Apache2::Request->new($r);
    my $code = $req->param('code');
    return unless $code;
    return unless ( $code =~ m/^(?:\d+)$/ );
    my $sql = "select active, ip from reg where code = ?";
    my $sth = $dbh->prepare($sql);
    $sth->bind_param( 1, $code );
    my $rv = $sth->execute;
    return unless $rv;
    my $cnt_arrayref = $sth->fetchrow_arrayref;
    return ( $cnt_arrayref, $code );
}

1;
