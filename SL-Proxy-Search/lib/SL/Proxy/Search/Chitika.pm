package SL::Proxy::Search::Chitika;

use strict;
use warnings;

use Apache2::RequestRec ();
use Apache2::RequestIO  ();
use Apache2::Const -compile => qw( DONE );
use Apache2::URI        ();

use HTML::Entities ();
use HTML::Template ();
use SL::Config     ();
use Data::Dumper qw(Dumper);
use URI::Escape ();

use constant DEBUG  => $ENV{SL_DEBUG}  || 0;
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
    $url =~ s/(url\=)([^&]+)/$1$Chitika_url/;
    my $referer = $2;

    if ($referer) {
	    $r->log->debug("url after chitika swap: $url, referer $referer") if DEBUG;

	    $url =~ s/(ref\=)([^&]+)/$1$referer/;
	    $r->log->debug("referer after chitika swap: $url, referer $referer") if DEBUG;
    }

    $r->pnotes(url => $url);

    $r->push_handlers( PerlResponseHandler => 'SL::Proxy->handler' );
    return Apache2::Const::DECLINED;
}

1;
