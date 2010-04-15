package SL::Proxy::Search;

use strict;
use warnings;

our $VERSION = 0.03;

use Apache2::RequestRec ();
use Apache2::RequestIO  ();
use Apache2::Const -compile => qw( SERVER_ERROR DONE OK );
use Apache2::URI        ();

use HTML::Entities ();
use HTML::Template ();
use Google::Search ();
use SL::Config     ();
use Data::Dumper qw(Dumper);
use RHP::Timer     ();

use constant DEBUG  => $ENV{SL_DEBUG}  || 0;
use constant TIMING => $ENV{SL_TIMING} || 0;

our $Config  = SL::Config->new;
our $Timer   = RHP::Timer->new();
our $Searchtimer  = RHP::Timer->new();
our $Referer = $Config->sl_gsearch_referer;
our $Key     = $Config->sl_gsearch_key;

our $Template = HTML::Template->new(
        filename          => $Config->sl_httpd_root . '/htdocs/sl_search.tmpl',
	die_on_bad_params => 0 );

sub handler {
    my $r = shift;

    $Searchtimer->start('searchtimer');
    $Timer->start('url parsing') if TIMING;
    my $uri = $r->unparsed_uri;
    my ($q) = $uri =~ m/[&]?q=([^&]+)[&]?/;

    # save this for later
    my $plusq = $q; 

    $r->log->debug("q is $q") if DEBUG;
    Apache2::URI::unescape_url($q);
   
    $r->log->debug("q unescaped is $q") if DEBUG;
    $q =~ s/\+/ /g;

    $r->log->debug("q minus +s is $q") if DEBUG;

    $r->log->info(
        sprintf( "$$ timer $$ %s %s %d %s %f", @{ $Timer->checkpoint } ) )
      if TIMING;

    # start the search
    $Timer->start('google search') if DEBUG;

    my $search = Google::Search->Web(
        q => $q,
        key => $Key,
        referer => $Referer);

    $r->log->info(
        sprintf( "$$ timer $$ %s %s %d %s %f", @{ $Timer->checkpoint } ) )
      if TIMING;

    my @results;
    my $i = 1;
    my $limit = 25;
    $Timer->start('results parsing') if TIMING;
    while( my $result = $search->next ) {

	last if ++$i > $limit;
        my %hash = map { $_ => $result->{_content}->{$_}  } keys %{$result->{_content}};
	unless ($hash{'visibleUrl'} =~ m{/}) {

            $hash{'visibleUrl'} .= '/';
        }

	push @results, \%hash;
    }

    $r->log->info(
        sprintf( "$$ timer $$ %s %s %d %s %f", @{ $Timer->checkpoint } ) )
      if TIMING;

    $r->log->debug(Dumper(\@results)) if DEBUG;

    $q = HTML::Entities::encode_numeric($q);
    $q ||= '';
    $r->log->debug("q is '$q'") if DEBUG;

    if (DEBUG) {
        $Template = HTML::Template->new(
            filename => $Config->sl_httpd_root . '/htdocs/sl_search.tmpl',
	    die_on_bad_params => 0 );
    }

    my ($pkg, $file, $line, $timer_name, $interval) = @{ $Searchtimer->checkpoint };
    $r->log->info(
        sprintf( "$$ timer $$ %s %s %d %s %f",
		$pkg, $file, $line, $timer_name, $interval ) ) if TIMING;

    $r->log->debug("search time $interval") if DEBUG;

    $Timer->start('page rendering') if TIMING;

    $Template->param(ACCOUNT_WEBSITE => $Config->sl_account_website);
    $Template->param(ACCOUNT_NAME => $Config->sl_account_name);
    $Template->param(QUERY_TIME => sprintf("%1.2f", $interval));
    $Template->param(PLUSQUERY => $plusq);
    $Template->param(QUERY => $q);
    $Template->param(QUERY_LIMIT => $limit);
    $Template->param(SEARCH_RESULTS => \@results);
    $Template->param(CHITIKA_ID => $Config->sl_chitika_id);
    $r->content_type('text/html; charset=ISO-8859-1');

    $r->rflush;
    my $output = $Template->output;
    $r->print($output);

    $r->log->info(
        sprintf( "$$ timer $$ %s %s %d %s %f", @{ $Timer->checkpoint } ) )
      if TIMING;


    return Apache2::Const::OK;
}


1;
