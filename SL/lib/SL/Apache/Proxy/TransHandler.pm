package SL::Apache::Proxy::TransHandler;

use strict;
use warnings;

=head1 NAME
 
SL::Apache::TransHandler

=head1 SYNOPSIS

=cut

use SL::Model      ();
use SL::Model::URL ();

our ($EXT_REGEX, $BLACKLIST_REGEX);
use Regexp::Assemble ();

our $VERBOSE_DEBUG = 0;

BEGIN {
    ## Extension based matching
    my @extensions = qw(
      ad avi bin bz2 css doc exe fla gif gz ico jpeg jpg js pdf png ppt rar
      sit rss tgz txt wmv vob xpi zip );

    $EXT_REGEX = Regexp::Assemble->new->add(@extensions)->re;
    print STDERR "Regex for static content match is $EXT_REGEX\n"
        if $VERBOSE_DEBUG;

    $BLACKLIST_REGEX = SL::Model::URL->generate_blacklist_regex;
    print STDERR "Blacklist reges is $BLACKLIST_REGEX\n" if $VERBOSE_DEBUG;

}

use Apache2::Const -compile =>
  qw( OK SERVER_ERROR NOT_FOUND DECLINED CONN_KEEPALIVE DONE LOG_INFO );
use Apache2::Connection     ();
use Apache2::RequestRec     ();
use Apache2::RequestUtil    ();
use Apache2::ServerRec      ();
use Apache2::ServerUtil     ();
use Apache2::URI            ();
use SL::Cache               ();
use SL::Util                ();
use RHP::Timer              ();
use SL::Cache				();
use SL::Cache::Subrequest   ();

our $CACHE = SL::Cache->new( type => 'raw' );
our $SUBREQUEST_TRACKER = SL::Cache::Subrequest->new;

my $TIMER = RHP::Timer->new();

sub proxy_request {
    my $r = shift;
    if ($r->dir_config('SLProxy') eq 'perlbal') {
        return &perlbal($r);
    }
    elsif ($r->dir_config('SLProxy') eq 'mod_proxy') {
        return &mod_proxy($r);
    }
}

sub static_content_uri {
    my $url = shift;
    if ($url =~ m{\.(?:$EXT_REGEX)$}i) {
        return 1;
    }
}

sub handler {
    my $r = shift;

    # start the clock
    $TIMER->start('initialization')
      if ($r->server->loglevel() == Apache2::Const::LOG_INFO);

	return &proxy_request($r) if ($r->pnotes('ua') eq 'none');
    my $url = $r->construct_url($r->unparsed_uri);
    my $referer = $r->headers_in->{'referer'} || 'no_referer';

    $r->pnotes('url'     => $url);
    $r->pnotes('referer' => $referer);

    # checkpoint
    if ($r->server->loglevel() == Apache2::Const::LOG_INFO) {
        $r->log->info(
             sprintf("timer $$ %s %d %s %f", @{$TIMER->checkpoint}[0, 2 .. 4]));

        # reset the clock
        $TIMER->start('db_mod_proxy_filters');

    }

    # first check that a database handle is available
    my $dbh = SL::Model->connect();
    unless ($dbh) {
        $r->log->error("Database has gone away, sending to mod_proxy");
        return &proxy_request($r);
    }

    # our secret namespace
    if ($url =~ m!/sl_secret_ping_button!) {
        return Apache2::Const::OK;
    }
    # allow /sl_secret_blacklist_button to pass through
    if ($url =~ m!/sl_secret_blacklist_button$!) {
        return Apache2::Const::OK;
    }
    if ($url =~ m!/sl_secret_status!) {
        return Apache2::Const::OK;
    }

	# User and content driven handling
    # Close this bar
    return &proxy_request($r) if user_blacklisted($r, $dbh);

    if ($r->server->loglevel() == Apache2::Const::LOG_INFO) {
        $r->log->info(
             sprintf("timer $$ %s %d %s %f", @{$TIMER->checkpoint}[0, 2 .. 4]));
        $TIMER->start('url_blacklisted');
    }

    # blacklisted urls
	return &proxy_request($r) if (url_blacklisted($url));
	#return &proxy_request($r) if$CACHE->url_blacklisted($url);

    if ($r->server->loglevel() == Apache2::Const::LOG_INFO) {
        $r->log->info(
             sprintf("timer $$ %s %d %s %f", @{$TIMER->checkpoint}[0, 2 .. 4]));
        $TIMER->start('not_a_browser');
    }

    ## Handle non-browsers that use port 80
    return &proxy_request($r) if (_not_a_browser($r));

    # we only serve ads on GETs
    return &proxy_request($r) if ($r->method ne 'GET');

    if ($r->server->loglevel() == Apache2::Const::LOG_INFO) {
        $r->log->info(
             sprintf("timer $$ %s %d %s %f", @{$TIMER->checkpoint}[0, 2 .. 4]));
        $TIMER->start('examine_request');
    }

    ## Static content
    if (static_content_uri($url)) {
        $r->log->debug("$$ Url $url static content extension, proxying");
        return &proxy_request($r);
    }

    # check for sub-reqs if it passed the other tests
    my $is_subreq = $SUBREQUEST_TRACKER->is_subrequest(url => $url);
	#$r->log->debug("$$ ===> $url is_subreq: $is_subreq");
    return &proxy_request($r) if $is_subreq;

    ## Check the cache for a static content match
    return mod_proxy($r) if $CACHE->is_known_not_html($url);
	$r->log->debug("EndTranshandler");

    if ($r->server->loglevel() == Apache2::Const::LOG_INFO) {
        $r->log->info(
             sprintf("timer $$ %s %d %s %f", @{$TIMER->checkpoint}[0, 2 .. 4]));
    }

    return Apache2::Const::OK;
}

sub user_blacklisted {
    my ($r, $dbh) = @_;

    my $user_id = join("|",
                       $r->connection->remote_ip, $r->pnotes('ua'),
                       $r->construct_server());

    my $sth =
      $dbh->prepare(
                 "SELECT count(user_id) FROM user_blacklist WHERE user_id = ?");
    $sth->bind_param(1, $user_id);
    $sth->execute;
    my $ary_ref = $sth->fetchrow_arrayref;
    return 1 if $ary_ref->[0] > 0;
    return;
}

sub url_blacklisted {
    my $url = shift;

    my $ping = SL::Model::URL->ping_blacklist_regex;
    if ($ping) { # update the blacklist if it has changed
        $BLACKLIST_REGEX = $ping;
    }
    return 1 if ($url =~ m{$BLACKLIST_REGEX}i);
}

# extract this to a utility library or something
sub _not_a_browser {
    my $r = shift;

    # all browsers start with Mozilla, at least in apache
    if (substr($r->pnotes('ua'), 0, 7) eq 'Mozilla') {
        return;
    }

    $r->log->debug("$$ This is not a browser: " . $r->pnotes('ua'));
    return 1;
}

sub mod_proxy {
    my $r = shift;

    ## Don't change this next line even if you think you should
    my $url = $r->construct_url;

    ## Use mod_proxy to do the proxying
    $r->log->debug("$$ mod_proxy handling request for $url");
    $r->uri($url);

    # Don't change this stuff either unless you are on a desert island alone
    $r->filename("proxy:$url");
    $r->handler('proxy-server');
    $r->proxyreq(1);
    return Apache2::Const::DECLINED;
}

sub perlbal {
    my $r = shift;

    ##########
    # Use perlbal to do the proxying
    $r->log->debug("Using perlbal to reproxy request");
    my $uri = $r->construct_url($r->unparsed_uri);
    $r->headers_out->add('X-REPROXY-URL' => $r->construct_url);
    return Apache2::Const::DONE;
}

1;
