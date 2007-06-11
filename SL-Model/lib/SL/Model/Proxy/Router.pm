package SL::Model::Proxy::Router;

use strict;
use warnings;

use base 'SL::Model';

use constant ACTIVE_SQL =>
  q{SELECT count(router_id) FROM router WHERE ip = ? and active = 't'};

sub is_active {
    my ( $class, $args_ref ) = @_;

    my $sth = $class->connect->prepare_cached(ACTIVE_SQL);
    $sth->bind_param( 1, $args_ref->{'ip'} );
    $sth->execute;
    return $sth->fetchrow_arrayref->[0];
}

sub register {
    my ( $class, $args_ref ) = @_;

    my ( $sql, $sth );
    if ( $args_ref->{'macaddr'} ) {
        $sql = 'INSERT INTO router (ip, macaddr, active) VALUES (?, ?, \'t\')';
        $sth = $class->connect->prepare_cached($sql);
        $sth->bind_param( 1, $args_ref->{'ip'} );
        $sth->bind_param( 2, $args_ref->{'macaddr'} );
    }
    else {
        $sql = 'INSERT INTO router (ip, active) VALUES (?, \'t\')';
        $sth = $class->connect->prepare_cached($sql);
        $sth->bind_param( 1, $args_ref->{'ip'} );
    }

    # return on failure
    $sth->execute or return;

    # return true
    return 1;
}

1;