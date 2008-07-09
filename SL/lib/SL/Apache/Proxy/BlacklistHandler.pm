package SL::Apache::Proxy::BlacklistHandler;

use strict;
use warnings;

use Apache2::Const -compile => qw( REDIRECT SERVER_ERROR );
use Apache2::Connection ();

use SL::Model  ();
use SL::Config ();

our $CONFIG;

BEGIN {
    $CONFIG = SL::Config->new;
}

use constant DEBUG => $ENV{SL_DEBUG} || 0;
use constant BLACKLIST_SQL => q{
SELECT user_id, ts FROM user_blacklist WHERE user_id = ?
};

sub handler {
    my $r = shift;

    # grab the sl header or fail
    my $sl_header = $r->headers_in->{'x-sl'};
    if ( $sl_header ) {
        $r->pnotes( 'sl_header' => $sl_header );
        $r->log->debug("$$ Found sl_header $sl_header") if DEBUG;

        my ( $hash_mac, $router_mac ) =
          split ( /\|/, $r->pnotes('sl_header') );

        $r->log->debug("$$ router $router_mac, hash_mac $hash_mac")
          if DEBUG;

        unless ( $router_mac && $hash_mac ) {
            $r->log->error("$$ sl_header present but no hash or router mac");
            return Apache2::Const::SERVER_ERROR;    # not really anything better
        }

    }
    else {

        $r->log->error(
            sprintf( "$$ blacklist handler with url %s but no sl header",
                $r->construct_url( $r->unparsed_uri ) )
        );
        return Apache2::Const::SERVER_ERROR;
    }

    my $user_id = join ( '|', $sl_header, $r->construct_server );
    $r->log->debug("===> user blacklist handler, user_id $user_id") if DEBUG;

    my $dbh = SL::Model->connect();
    unless ($dbh) {
        $r->log->error(
            sprintf( "package %s db connect failed err: %s", __PACKAGE__, $@ )
        );
        return Apache2::Const::SERVER_ERROR;
    }

    # look for existing blacklist entries
    my $select_sth = $dbh->prepare(BLACKLIST_SQL);
    $select_sth->bind_param( 1, $user_id );
    my $rv = $select_sth->execute;
    if ( !$rv ) {
        $r->log->error(
            sprintf(
                "$$ user_blacklist err, uid %s, err %s, url %s, referer %s",
                $user_id, $@, $r->pnotes('url'), $r->pnotes('referer')
            )
        );
        return Apache2::Const::SERVER_ERROR;
    }

    # no error, see if it has been blacklisted already
    my $ary_ref = $select_sth->fetchrow_arrayref;
    $select_sth->finish;

    if ( defined $ary_ref->[0] ) {

        # ok an entry exists, someone is trying to blacklist it again?
        $r->log->error(
            sprintf(
                "re-blacklist attempt, user_id %s, url %s, ts %s, referer %s",
                $user_id,      $r->pnotes('url'),
                $ary_ref->[1], $r->pnotes('referer')
            )
        );
        return _redirect( $r, $user_id );
    }

    # not blacklisted yet, add it
    my $sth =
      $dbh->prepare("INSERT INTO user_blacklist (user_id) values ( ? )");
    $sth->bind_param( 1, $user_id );
    $rv = $sth->execute;
    unless ($rv) {

        # something is busted!  probably the database
        $r->log->error(
            sprintf(
                "$$ blacklist failed, uid %s, url %s, referer %s, err %s",
                $user_id,              $r->pnotes('url'),
                $r->pnotes('referer'), $DBI::errstr
            )
        );
        return Apache2::Const::SERVER_ERROR;
    }

    # blacklist happened ok
    $r->log->debug(
        sprintf(
            "%s blacklist successful for uid %s, referer %s",
            $r->pnotes('url'), $user_id, $r->pnotes('referer')
        )
      )
      if DEBUG;
    return _redirect( $r, $user_id );
}

sub _redirect {
    my ( $r, $user_id ) = @_;
    if (   ( $r->pnotes('referer') eq 'no_referer' )
        or ( !$r->pnotes('referer') ) )
    {

        # if no referer redirect to the root url
        $r->log->error(
            sprintf(
                "no referer, uid %s sending to base domain %s",
                $user_id, $r->construct_url('/')
            )
        );
        $r->headers_out->set( Location => $r->construct_url('/') );
    }
    else {

        # redirect back to the referring page
        $r->headers_out->set( Location => $r->pnotes('referer') );
    }
    $r->server->add_version_component('sl');

    $r->no_cache(1);

    return Apache2::Const::REDIRECT;
}

1;
