package SL::CS::Apache::Ad;

use strict;
use warnings;

use Apache2::Const -compile => qw( OK );
use Apache2::Log;
use Apache2::RequestRec;
use SL::CS::Model;
use SL::CS::Model::Ad;

my $sql = <<SQL;
INSERT INTO view
( ad_id, ip ) values ( ?, ? )
SQL

sub handler {
    my $r = shift;

    die unless $r->method eq 'GET';
    $r->log->info( "$$ AD SERVED request, uri " . $r->uri );

    my $ip;
    unless (($ip) = $r->args =~ /ip=(\d+\.\d+\.\d+\.\d+)/g) {
    	$ip = '0.0.0.0';
    }
    my $ad = SL::CS::Model::Ad->random;

    $r->log->debug( "Ad content is : ", $ad->as_html );
    $r->no_cache(1);
    $r->content_type('text/html');
    $r->print( $ad->as_html );
    $r->rflush();

    my $dbh = SL::CS::Model->db_Main();
    my $sth = $dbh->prepare($sql);
    $sth->bind_param( 1, $ad->{'ad_id'} );
    $sth->bind_param( 2, $ip);
    my $rv = $sth->execute;
    if ( !$rv ) {
        $r->log->error(
            "$$ Error logging view - rv => $rv, dbi_err => " . $DBI::errstr );
        $dbh->rollback;
    }
    else {
        $r->log->error( "$$ logging view for ad " . $ad->{'ad_id'} );
        $dbh->commit;
    }

    return Apache2::Const::OK;
}

1;
