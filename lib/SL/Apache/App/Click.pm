package SL::Apache::App::Click;

use strict;
use warnings;

use Apache2::Const -compile => qw( NOT_FOUND SERVER_ERROR REDIRECT );
use Apache2::Log;
use Apache2::RequestIO;
use Apache2::RequestRec ();
use APR::Table ();
use DBD::Pg qw(:pg_types);
use SL::Model;

sub handler {
    my $r = shift;

    return Apache2::Const::NOT_FOUND unless $r->method eq 'GET';
    $r->log->debug("$$ URI is ", $r->uri);
    my ($md5) = $r->uri =~ m/([^\/]+)$/;

    unless (defined $md5 && length($md5) == 32) {
        return Apache2::Const::NOT_FOUND;
    }
    $r->log->debug("$$ MD5 is $md5");

    my $dbh = SL::Model->db_Main();

    my $statement = <<END;
SELECT link_id, uri
FROM link
WHERE link.md5 = ?
END
    
    my $sth = $dbh->prepare( $statement );
    $sth->bind_param( 1, $md5, );#{ pg_type => PG_VARCHAR } );
    my $rv = $sth->execute;
    unless ( $rv ) {
        $r->log->error("$$ Could not find link for md5 $md5");
        $dbh->rollback;
        return Apache2::Const::SERVER_ERROR;
    }

    my $ary_ref = $sth->fetchrow_arrayref;
    require Data::Dumper;
    $r->log->debug("$$ Clicking link: " . Data::Dumper::Dumper($ary_ref));

    $statement = <<END;
INSERT INTO click
( link_id, ip ) values ( ?, ? )
END
    
    $sth = $dbh->prepare( $statement );
    $sth->bind_param( 1, $ary_ref->[0]);# { pg_type => PG_INTEGER } );
    $sth->bind_param( 2, $r->connection->remote_ip);
    $rv = $sth->execute;
    unless ( $rv ) {
        $r->log->error("$$ Could log find link for md5 $md5");
        $dbh->rollback;
    } else {
        $r->log->debug("$$ Logged click through for link ", $ary_ref->[0]);
        $dbh->commit;
    }

    # Now redirect
    $r->log->debug("$$ Redirecting to ", $ary_ref->[1] );
    $r->headers_out->set( Location => $ary_ref->[1] );
    return Apache2::Const::REDIRECT;
}

1;
