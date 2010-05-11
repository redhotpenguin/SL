package SL::Apache2::Search;

use strict;
use warnings;

our $VERSION = 0.01;

=head1 NAME

SL::Apache2::Search - mod_perl2 silverlining search handler

=cut

use Apache2::Response   ();
use Apache2::Request    ();
use Apache2::RequestRec ();
use Apache2::RequestIO  ();
use Apache2::Const -compile => qw( SERVER_ERROR DONE OK );
use Apache2::URI ();

use HTML::Entities ();
use HTML::Template ();
use Google::Search ();
use SL::Config     ();
use Data::Dumper qw(Dumper);
use RHP::Timer          ();
use Encode              ();
use WebService::Viglink ();
use Digest::MD5         ();

use constant DEBUG         => $ENV{SL_DEBUG}         || 0;
use constant VERBOSE_DEBUG => $ENV{SL_VERBOSE_DEBUG} || 0;
use constant TIMING        => $ENV{SL_TIMING}        || 0;

our $Config   = SL::Config->new;
our $Vkey     = $Config->sl_viglink_apikey;
our $Filename = $Config->sl_root . '/htdocs/sl_search.tmpl';
our $Template = HTML::Template->new(
    filename          => $Filename,
    die_on_bad_params => 0
);

our $Fivehundred =
  HTML::Template->new( filename => $Config->sl_root . '/htdocs/errors/500.html',
  );
$Fivehundred->param( static_href => 'http://s.slwifi.com' );
$Fivehundred = $Fivehundred->output;

our $Viglink = WebService::VigLink->new( { 'key' => $Vkey } );

our $Timer       = RHP::Timer->new();
our $Searchtimer = RHP::Timer->new();
our $Referer     = $Config->sl_gsearch_referer;
our $Key         = $Config->sl_gsearch_key;
our $Chitika_id =  $Config->sl_chitika_id;

sub handler {
    my $r = shift;

    my $req = Apache2::Request->new($r);

    my @search_results;
    my $q = $req->param('q');
    if ( defined $q && ( $q ne '' ) ) {

        $Searchtimer->start('searchtimer');

        my %search_args = ( q => $q, key => $Key, referer => $Referer );
        my $start = $req->param('start') || 0;

        $search_args{start} = $start;

        my $search = eval { Google::Search->Web(%search_args) };
        if ($@) {
            $r->log->error(
                sprintf(
                    "Search for %s failed err %s",
                    Dumper( \%search_args ), $@
                )
            );
            $r->custom_response( Apache2::Const::SERVER_ERROR, $Fivehundred );
            return Apache2::Const::SERVER_ERROR;
        }

        my $i     = 1;
        my $limit = 10;
        while ( my $result = $search->next ) {

            $r->log->debug( Dumper($result) ) if DEBUG;

            last if ++$i > $limit;
            my %hash = map { $_ => $result->{_content}->{$_} }
              keys %{ $result->{_content} };

            if ( defined $hash{'content'} ) {
                my $content = $hash{'content'};
                $hash{'content'} =
                  eval { Encode::decode( 'utf8', $hash{'content'} ) };
                if ($@) {
                    $r->log->error(
                        "encoding error: $@ for " . $hash{'content'} );
                    $hash{'content'} = $content;
                }
            }
            if ( defined $hash{'title'} ) {
                my $title = $hash{'title'};
                $hash{'title'} =
                  eval { Encode::decode( 'utf8', $hash{'title'} ) };
                if ($@) {
                    $r->log->error(
                        "encoding error: $@ for title " . $hash{'title'} );
                    $hash{'title'} = $title;
                }
            }

            unless ( $hash{'visibleUrl'} =~ m{/} ) {

                $hash{'visibleUrl'} .= '/';
            }

            my $loc = $r->construct_url( $r->unparsed_uri );

            my $ref = $r->headers_in->{'Referer'}
              || 'http://search.slwifi.com/';

            $hash{'url'} = $Viglink->make_url(
                {
                    out  => $hash{'unescapedUrl'},
                    cuid => Digest::MD5::md5_hex( $r->connection->remote_ip ),
                    loc  => $loc,
                    referrer => $ref,
                    txt      => $hash{'title'},
                    title    => $Config->sl_account_name
                      . " - Custom Search for '$q'",
                }
            );

            push @search_results, \%hash;
        }

        $r->log->debug( Dumper( \@search_results ) ) if VERBOSE_DEBUG;

        $q = HTML::Entities::encode_numeric($q);
        $q ||= '';

        if (DEBUG) {
            $Template = HTML::Template->new(
                filename          => $Filename,
                die_on_bad_params => 0
            );
        }

        my ( $pkg, $file, $line, $timer_name, $interval ) =
          @{ $Searchtimer->checkpoint };

        $r->log->info(
            sprintf(
                "$$ timer $$ %s %s %d %s %f",
                $pkg, $file, $line, $timer_name, $interval
            )
        ) if TIMING;

        $r->log->debug("search time $interval") if VERBOSE_DEBUG;

        $r->log->debug("Start is $start");
        my $plus_q = $q;
        $plus_q =~ s/ /\+/g;

        $Template->param( QUERY_TIME => sprintf( "%1.2f", $interval ) );
        $Template->param( QUERY      => $q );
        $Template->param( PLUSQUERY  => $plus_q );
        $Template->param( START      => $start );
        $Template->param( START_PARAM => $start + 1 );
        $Template->param( FINISH      => $start + 10 );

        if ( $start > 9 ) {
            $Template->param( PREV       => 1 );
            $Template->param( PREV_START => $start - 10 );
        }
        else {
            $Template->param( PREV => 0 );
        }

        if ( $start < 50 ) {
            $Template->param( NEXT => $start + 10 );
        }
        else {
            $Template->param( NEXT => 0 );
        }

        my @numbers;
        for ( 1 .. 6 ) {

            my %nums = (
                start => ( ( $_ - 1 ) * 10 ),
                marker    => $_,
                plusquery => $plus_q
            );

            if ( $start == $nums{start} ) {
                $nums{current} = 1;
            }

            push @numbers, \%nums;
        }

        $Template->param( NUMBERS        => \@numbers );
        $Template->param( SEARCH_RESULTS => \@search_results );


        my $clicksor_code = <<CLICKSOR_CODE;
<script type="text/javascript">
clicksor_layer_border_color = '';
clicksor_layer_ad_bg = ''; clicksor_layer_ad_link_color = '';
clicksor_layer_ad_text_color = ''; clicksor_text_link_bg = '';
clicksor_text_link_color = '#290cff'; clicksor_enable_text_link = true;
</script>
<script type="text/javascript" src="http://ads.clicksor.com/showAd.php?nid=1&amp;pid=135461&amp;adtype=&amp;sid=202522"></script>
<noscript><a href="http://www.bannercenter.net">web banner design</a></noscript>
CLICKSOR_CODE


        my $topadcode =  <<"TOPADCODE";
<script type="text/javascript">
ch_client = "$Chitika_id";
ch_type = "mpu";
ch_width = 728;
ch_height = 90;
ch_non_contextual = 4;
ch_vertical ="premium";
ch_backfill = 1;
ch_sid = "Chitika Premium";
var ch_queries = new Array( );
var ch_selected=Math.floor((Math.random()*ch_queries.length));
if ( ch_selected < ch_queries.length ) {
ch_query = ch_queries[ch_selected];
}
</script>
<script  src="http://scripts.chitika.net/eminimalls/amm.js" type="text/javascript">
</script>
TOPADCODE


        $Template->param( TOPADCODE => $topadcode);

        my $sideadcode = <<"SIDEADCODE";
<script type="text/javascript">
ch_client = "$Chitika_id";
ch_type = "mpu";
ch_width = 160;
ch_height = 600;
ch_backfill = 1;
ch_non_contextual = 4;
ch_vertical ="premium";
ch_sid = "Chitika Premium";
var ch_queries = new Array( );
var ch_selected=Math.floor((Math.random()*ch_queries.length));
if ( ch_selected < ch_queries.length ) {
ch_query = ch_queries[ch_selected];
}
</script>
<script  src="http://scripts.chitika.net/eminimalls/amm.js" type="text/javascript">
</script>
SIDEADCODE

        $Template->param( SIDEADCODE => $sideadcode);
    }

    $Template->param( ACCOUNT_WEBSITE => $Config->sl_account_website );
    $Template->param( ACCOUNT_NAME    => $Config->sl_account_name );

    $Template->param( STATIC_HREF => 'http://s.slwifi.com' );

    $r->content_type('text/html; charset=UTF-8');

    $r->no_cache(1);
    $r->rflush;
    my $output = $Template->output;
    $r->print($output);

    return Apache2::Const::OK;
}

1;
__END__

=head1 SYNOPSIS

  PerlResponseHandler SL::Apache2::Search

=head1 DESCRIPTION

Does searching.

=head1 AUTHOR

Fred Moyer <fred@slwifi.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2010 by Silver Lining Networks.

This software is proprietary under the Silver Lining Networks software license.

=cut
