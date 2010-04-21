package SL::Proxy::Search::Chitika;

use strict;
use warnings;

use Apache2::RequestRec ();
use Apache2::RequestIO  ();
use Apache2::Const -compile => qw( DONE );
use Apache2::URI        ();

use Apache2::Connection ();

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

    $r->log->debug("chitika handler " . $r->connection->id . ",  for $url") if DEBUG;

    # replace the source url with the account url
    my $url_reps = $url =~ s/(url\=)([^&]+)/$1$Chitika_url/;
    my $orig_url = $2;
    unless ($orig_url) {

        # this is an odd condition that occurs under Chrome when it sends a chitika
        # request without the parameters: http://mm.chitika.net/minimall?
	$r->log->debug("no url param for $url, conn id " . $r->connection->id) if DEBUG;

	return Apache2::Const::DONE;
    }

    $r->log->debug("replaced url $orig_url with $Chitika_url") if DEBUG;

    if (my ($ref) = $url =~ m/\&ref\=([^&]+)/) {

	# replace the referer
        my $repl_count = $url =~ s/\Q$ref\E/$orig_url/;
	$r->log->debug("replaced $repl_count ref $ref with $orig_url") if DEBUG;

    } else {

        # url does not contain a referer, add it
	$url .= "&ref=$orig_url";
	$r->log->debug("added ref $orig_url");
    }

    $r->log->debug("new url is $url") if DEBUG;;
    $r->pnotes(url => $url);

   # $r->push_handlers( PerlResponseHandler => 'SL::Proxy->handler' );
    return Apache2::Const::DECLINED;
}

1;
