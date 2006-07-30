package SL::CS::Apache::Ad;

use strict;
use warnings;

use Apache2::Const -compile => qw( OK HTTP_NOT_FOUND );
use Apache2::Log;
use Apache2::RequestRec;
use SL::CS::Model;
use SL::CS::Model::Ad;

my $sql = <<SQL;
INSERT INTO view
( ad_id ) values ( ? )
SQL

sub handler {
    my $r = shift;

    die unless $r->method eq 'GET';
    $r->log->info( "$$ AD SERVED request, uri " . $r->uri );

    # look for group params and get ads for the groups if available
    my $ad;
    if (my @groups = $r->args =~ /g=(\d+)/g) {
        $ad = SL::CS::Model::Ad->random(\@groups);
    } else {
        $ad = SL::CS::Model::Ad->random;
    }
    
    # no ad found
    unless ($ad) {
        return Apache2::Const::HTTP_NOT_FOUND;
    }

    $r->log->debug( "Ad content is : ", $ad->as_html );
    $r->no_cache(1);
    $r->content_type('text/html');
    $r->print( $ad->as_html );
    $r->rflush();

    my $dbh = SL::CS::Model->db_Main();
    my $sth = $dbh->prepare($sql);
    $sth->bind_param( 1, $ad->{'ad_id'} );
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
