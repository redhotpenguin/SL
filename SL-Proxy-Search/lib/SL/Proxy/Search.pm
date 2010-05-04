package SL::Proxy::Search;

use strict;
use warnings;

use Apache2::Request    ();
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
use Encode         ();
use WebService::Viglink ();
use Digest::MD5 ();

use constant DEBUG  => $ENV{SL_DEBUG}  || 0;
use constant VERBOSE_DEBUG  => $ENV{SL_VERBOSE_DEBUG}  || 0;
use constant TIMING => $ENV{SL_TIMING} || 0;

our $VERSION = 0.03;

our $Config  = SL::Config->new;
our $Timer   = RHP::Timer->new();
our $Searchtimer  = RHP::Timer->new();
our $Referer = $Config->sl_gsearch_referer;
our $Key     = $Config->sl_gsearch_key;

our $Viglink = WebService::Viglink->new({
    key => $Config->sl_viglink_apikey,
    format => 'go', });

warn("viglink is " . Dumper($Viglink));

our $Template = HTML::Template->new(
        filename          => $Config->sl_httpd_root . '/htdocs/sl_search.tmpl',
	die_on_bad_params => 0 );

sub handler {
    my $r = shift;

    my $req = Apache2::Request->new($r);

    $Searchtimer->start('searchtimer');
    $Timer->start('url parsing') if TIMING;
    my $uri = $r->unparsed_uri;
    my $q = $req->param('q');

    # save this for later
    my $plusq = $q; 
    $plusq =~ s/ /\+/g;

    $r->log->debug("q is '$q'") if DEBUG;

    $r->log->info(
        sprintf( "$$ timer $$ %s %s %d %s %f", @{ $Timer->checkpoint } ) )
      if TIMING;

    # start the search
    $Timer->start('google search') if DEBUG;

    my %search_args = ( q => $q, key => $Key, referer => $Referer );
    my $start = $req->param('start') || 0;

    $search_args{start} = $start;

    my $search = Google::Search->Web( %search_args );

    $r->log->info(
        sprintf( "$$ timer $$ %s %s %d %s %f", @{ $Timer->checkpoint } ) )
      if TIMING;

    my @results;
    my $i = 1;
    my $limit = 10;
    $Timer->start('results parsing') if TIMING;
    while( my $result = $search->next ) {

        $r->log->debug(Dumper($result)) if DEBUG;

	last if ++$i > $limit;
        my %hash = map { $_ => $result->{_content}->{$_}  }
		keys %{$result->{_content}};

        if (defined $hash{'content'}) {
            my $content = $hash{'content'};
            $hash{'content'} = eval { Encode::decode('utf8', $hash{'content'}) };
             if ($@) {
               $r->log->error("encoding error: $@ for " . $hash{'content'});
                $hash{'content'} = $content;
            } 
        }
        if (defined $hash{'title'}) {
            my $title = $hash{'title'};
            $hash{'title'} = eval { Encode::decode('utf8', $hash{'title'}) };
            if ($@) {
               $r->log->error("encoding error: $@ for title " . $hash{'title'});
                $hash{'title'} = $title;
            }
        }

	unless ($hash{'visibleUrl'} =~ m{/}) {

            $hash{'visibleUrl'} .= '/';
        }

        my $loc = $r->construct_url($r->unparsed_uri);
        $loc =~ s/google/slwifi/g;

        my $ref = $r->headers_in->{'Referer'} || 'http://www.slwifi.com/';
        $ref =~ s/google/slwifi/g;

        $hash{'url'} = $Viglink->make_url({
            out          => $hash{'unescapedUrl'},
            cuid         => Digest::MD5::md5_hex($r->connection->remote_ip),
            loc          => $loc,
            referrer     => $ref,
            txt          => $hash{'title'},
            title        => $Config->sl_account_name . " - Custom Search for '$q'",
        });

	push @results, \%hash;
    }

    $r->log->info(
        sprintf( "$$ timer $$ %s %s %d %s %f", @{ $Timer->checkpoint } ) )
      if TIMING;

    $r->log->debug(Dumper(\@results)) if VERBOSE_DEBUG;

    $q = HTML::Entities::encode_numeric($q);
    $q ||= '';

    if (DEBUG) {
        $Template = HTML::Template->new(
            filename => $Config->sl_httpd_root . '/htdocs/sl_search.tmpl',
	    die_on_bad_params => 0 );
    }

    my ($pkg, $file, $line, $timer_name, $interval)
	= @{ $Searchtimer->checkpoint };

    $r->log->info(
        sprintf( "$$ timer $$ %s %s %d %s %f",
		$pkg, $file, $line, $timer_name, $interval ) ) if TIMING;

    $r->log->debug("search time $interval") if VERBOSE_DEBUG;

    $r->log->debug("Start is $start");
    $Timer->start('page rendering') if TIMING;

    $Template->param(ACCOUNT_WEBSITE => $Config->sl_account_website);
    $Template->param(ACCOUNT_NAME => $Config->sl_account_name);

    $Template->param(QUERY_TIME => sprintf("%1.2f", $interval));
    $Template->param(PLUSQUERY => $plusq);
    $Template->param(QUERY => $q);

    $Template->param(START => $start);
    $Template->param(START_PARAM => $start+1);
    $Template->param(FINISH => $start+10);

    if ($start > 9) {
        $Template->param(PREV => 1);
        $Template->param(PREV_START => $start-10);
    } else {
        $Template->param(PREV => 0);
    }

    if ($start < 50) {
        $Template->param(NEXT => $start+10);
    } else {
        $Template->param(NEXT => 0);
    }

    my @numbers;
    for (1..6) {

        my %nums = ( start => (($_-1)*10), marker => $_, plusquery => $plusq );

        if ($start == $nums{start}) {
            $nums{current} = 1;
        }


=cut
        if ($_ < 6) {
            $nums{bgpos} = 60;
            $nums{bgwid} = 16;
        } elsif ($_ == 7) {
            $nums{bgpos} = 44;
            $nums{bgwid} = 16;
        } elsif ($_ == 6) {
            $nums{bgpos} = 76;
            $nums{bgwid} = 42;
        }
=cut

        push @numbers, \%nums;
    }

    $Template->param(NUMBERS         => \@numbers);
    $Template->param(SEARCH_RESULTS  => \@results);
    $Template->param(CHITIKA_ID      => $Config->sl_chitika_id);
    $r->content_type('text/html; charset=UTF-8');

    $r->no_cache(1);
    $r->rflush;
    my $output = $Template->output;
    $r->print($output);

    $r->log->info(
        sprintf( "$$ timer $$ %s %s %d %s %f", @{ $Timer->checkpoint } ) )
      if TIMING;


    return Apache2::Const::OK;
}


1;
