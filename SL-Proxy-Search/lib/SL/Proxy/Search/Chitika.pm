package SL::Proxy::Search::Chitika;

use strict;
use warnings;

use Apache2::RequestRec ();
use Apache2::RequestIO  ();
use Apache2::Const -compile => qw( DONE );
use Apache2::URI        ();
use Apache2::Request    ();

use HTML::Entities ();
use HTML::Template ();
use SL::Config     ();
use Data::Dumper qw(Dumper);
use URI::Escape ();

use constant DEBUG  => $ENV{SL_DEBUG}  || 0;
use constant VERBOSE_DEBUG  => $ENV{SL_VERBOSE_DEBUG}  || 0;
use constant TIMING => $ENV{SL_TIMING} || 0;

our $Timer;
if (TIMING) {
    require RHP::Timer;
    $Timer = RHP::Timer->new();
}

our $Config = SL::Config->new;

our $Chitika_url = URI::Escape::uri_escape($Config->sl_chitika_url);

sub handler {
    my $r = shift;

    my $url = $r->pnotes('url');
    my $req = Apache2::Request->new($r);

    $r->log->debug("chitika handler for $url") if VERBOSE_DEBUG;

    # replace the source url with the account url
    my $url_reps = $url =~ s/(url\=)([^&]+)/$1$Chitika_url/;
    my $orig_url = $2;
    unless ($orig_url) {
	$r->log->error("no url param");
	return Apache2::Const::SERVER_ERROR;
    }

    $r->log->debug("replaced url $orig_url with $Chitika_url") if DEBUG;

    if (my ($ref) = $url =~ m/\&ref\=([^&]+)/) {

	# replace the referer
        $url =~ s/$ref/$orig_url/;
	$r->log->debug("replaced ref $ref with $orig_url") if DEBUG;

    } else {

        # url does not contain a referer, add it
	$url .= "&ref=$orig_url";
	$r->log->debug("added ref $orig_url");
    }

    $r->pnotes(url => $url);

    $r->push_handlers( PerlResponseHandler => 'SL::Proxy->handler' );
    return Apache2::Const::DECLINED;
}

1;
