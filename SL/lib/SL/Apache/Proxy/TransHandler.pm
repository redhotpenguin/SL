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
      ad avi bin bz2 css doc exe fla flv gif gz ico jpeg jpg js pdf png ppt 
	  rar sit swf rss tgz txt wmv vob xpi zip );

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
use SL::Model::Ad::Google   ();

our $CACHE = SL::Cache->new( type => 'raw' );
our $SUBREQUEST_TRACKER = SL::Cache::Subrequest->new;

my $TIMER = RHP::Timer->new();

sub proxy_request {
    my ($r, $uri) = @_;
    if ($r->dir_config('SLProxy') eq 'perlbal') {
        return &perlbal($r, $uri);
    }
    elsif ($r->dir_config('SLProxy') eq 'mod_proxy') {
        return &mod_proxy($r, $uri);
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

	return &proxy_request($r) if ($r->pnotes('ua') eq 'none');
    my $url = $r->construct_url($r->unparsed_uri);
    my $referer = $r->headers_in->{'referer'} || 'no_referer';

    $r->pnotes('url'     => $url);
    $r->pnotes('referer' => $referer);

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

	# need to be a get to get a x-sl header, covers non GET requests also
	if (my $sl_header = $r->headers_in->{'x-sl'}) {
		$r->pnotes('sl_header' => $sl_header);
		$r->log->debug("$$ Found sl_header $sl_header");
	} else {
		# no sl header no request
		return &proxy_request($r);
	}

	## Handle non-browsers that use port 80
    return &proxy_request($r) if (_not_a_browser($r));
	
	## Static content
    if (static_content_uri($url)) {
        $r->log->debug("$$ Url $url static content extension, proxying");
        return &proxy_request($r);
    }

	## hack for google ads
	return &proxy_request($r) if ($referer =~ m/googlesyndication/);
	
	# if this is one of our google ads then log it and pass it
    # this needs to be before the blacklist check
    if (my $new_uri = SL::Model::Ad::Google->match_and_log({ url => $url,
                                               ip => $r->connection->remote_ip })) 
    {
		# HACK
		return &proxy_request($r) if ($new_uri eq '1'); # string or integer

		$r->log->debug("$$ google ad click match for url $url, ip " .
                       $r->connection->remote_ip . ", new uri $new_uri");
		$r->pnotes('google_override' => 1);
		my $new_url = $r->construct_url($new_uri);
		$r->pnotes(url => $new_url);
		$r->log->debug("NEW URL: $new_url");
		return &proxy_request($r);
#		my $cached_url = $PAGE_CACHE->cache_url({ url => $referer });
#		if ($cached_url) {
#			# the response handler handles the proxy for this so stash referer
#			$r->pnotes('referer' => $cached_url);
#			$r->headers_in->{Referer} = $cached_url;
#		}
    }

	# start the clock - the stuff above is all memory
    if ($r->server->loglevel() == Apache2::Const::LOG_INFO) {
        # start the clock
        $TIMER->start('db_mod_proxy_filters');
    }

    # first check that a database handle is available
    my $dbh = SL::Model->connect();
    unless ($dbh) {
        $r->log->error("Database has gone away, sending to mod_proxy");
        return &proxy_request($r);
    }

    # blacklisted urls
	return &proxy_request($r) if (url_blacklisted($url));

	# User and content driven handling
    # Close this bar
    return &proxy_request($r) if user_blacklisted($r, $dbh);

    # check for sub-reqs if it passed the other tests
    my $is_subreq = $SUBREQUEST_TRACKER->is_subrequest(url => $url);
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

    my $user_id;
    if (my $sl_header = $r->pnotes('sl_header')) {
      $user_id = join('|', $sl_header, $r->construct_server());
    } else {
      $user_id = join("|",
                       $r->connection->remote_ip, $r->pnotes('ua'),
                       $r->construct_server());
    }

	$r->log->debug("==> user_blacklist check with user_id $user_id");
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
    my ($r, $uri) = @_;

    ## Don't change this next line even if you think you should
    my $url = $r->construct_url;

    ## Use mod_proxy to do the proxying
    $r->log->debug("$$ mod_proxy handling request for $url,");
	#$r->log->debug("$$ new uri is $uri");
    $r->log->debug("$$ unparsed uri " . $r->unparsed_uri);

    # Don't change these lines either or you'll be hurting
    if ($uri) {
      $r->uri($uri);
      $r->unparsed_uri($uri);
    }

    # Don't change this stuff either unless you are on a desert island alone
    # with a solar powered computer
    $r->filename("proxy:$url");

    $r->log->debug("filename is " . $r->filename);
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
