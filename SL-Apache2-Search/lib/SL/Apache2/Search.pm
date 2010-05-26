package SL::Apache2::Search;

use strict;
use warnings;

our $VERSION = 0.01;

=head1 NAME

SL::Apache2::Search - mod_perl2 silverlining search handler

=cut

use Apache2::Connection ();
use Apache2::Response   ();
use Apache2::Request    ();
use Apache2::RequestRec ();
use Apache2::RequestIO  ();
use Apache2::Const -compile => qw( SERVER_ERROR DONE OK REDIRECT );
use Apache2::URI ();

use SL::Config ();
use SL::Search ();

use HTML::Entities ();
use HTML::Template ();
use Data::Dumper qw(Dumper);
use RHP::Timer                   ();
use WebService::CityGrid::Search ();
use Cache::Memcached ();

use constant DEBUG         => $ENV{SL_DEBUG}         || 0;
use constant VERBOSE_DEBUG => $ENV{SL_VERBOSE_DEBUG} || 0;
use constant TIMING        => $ENV{SL_TIMING}        || 0;

our $Config        = SL::Config->new;
our $Filename      = $Config->sl_root . '/htdocs/sl_search.tmpl';
our %Template_args = (
    filename          => $Filename,
    die_on_bad_params => 0,
    global_vars       => 1,
);

our $Fivehundred =
  HTML::Template->new( filename => $Config->sl_root . '/htdocs/errors/500.html',
  );
$Fivehundred->param( static_href => 'http://s.slwifi.com' );
$Fivehundred = $Fivehundred->output;

our $Timer       = RHP::Timer->new();
our $Searchtimer = RHP::Timer->new();

our $Memd = Cache::Memcached->new({ servers => [ '127.0.0.1:11211' ] });

sub handler {
    my $r = shift;

    my $req = Apache2::Request->new($r);

    # figure out what vhost we are
    my $hostname = $r->hostname;
    $r->log->debug(
        "handling host $hostname, client " . $r->connection->remote_ip )
      if DEBUG;

    if ( $hostname eq 'app.silverliningnetworks.com' ) {

        # redirect this app server request
        $r->headers_out->set( Location => "https://$hostname/" );
        return Apache2::Const::REDIRECT;
    }

    my $search_vhost = SL::Search->vhost( { host => $r->hostname } )
      || SL::Search->default_vhost;

    my @search_results;
    my $q        = $req->param('q');
    my $start    = $req->param('start') || 0;
    my $Template = HTML::Template->new(%Template_args);

    if ( defined $q && ( $q ne '' ) ) {

        $Searchtimer->start('searchtimer');

        my %search_args = (
            q         => $q,
            start     => $start,
            url       => $r->construct_url( $r->unparsed_uri ),
            remote_ip => $r->connection->remote_ip,
            referrer  => $r->headers_in->{'Referer'}
              || 'http://search.slwifi.com'
        );

        my $search_results = eval { $search_vhost->search( \%search_args ); };
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

        my ( $pkg, $file, $line, $timer_name, $interval ) =
          @{ $Searchtimer->checkpoint };

        $r->log->debug("search time $interval") if DEBUG;

        $r->log->debug( Dumper($search_results) ) if VERBOSE_DEBUG;

        # now ping citysearch
        my $last_search = $Memd->get('last_citygrid_searchtime') || 0;

        # hardcode to 1 search per second right now
        my $time = time();
        if ($time - $last_search > 0) {

            # ok to run a new search
            $Memd->set('last_citygrid_searchtime' => $time);
            my $cg = WebService::CityGrid::Search->new(
                api_key   => $search_vhost->{citygrid_api_key},
                publisher => $search_vhost->{citygrid_publisher}
            );
            my $cg_results = $cg->query(
                {
                    mode  => 'locations',
                    where => $search_vhost->{citygrid_where},
                    what  => URI::Escape::uri_escape($q),
                }
            );
            my $i = 0;
            my @refined;
            foreach my $cg_result ( @{$cg_results} ) {
                next unless $cg_result->tagline;
                next unless $cg_result->neighborhood;
                last if ++$i == 3;

                if ($i == 1) {
                    $cg_result->top_hit(1);
                }
                push @refined, $cg_result;
            }

            if (@refined) {
                $r->log->error(Dumper(\@refined));
                $Template->param( CG_ADS => \@refined );
            }
        }

        $q = HTML::Entities::encode_numeric($q);

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
        $Template->param( SEARCH_RESULTS => $search_results );

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


        $Template->param( SIDEADCODE => $search_vhost->{adserver_side} );
    }

    $Template->param( ACCOUNT_WEBSITE => $search_vhost->{account_website} );
    $Template->param( ACCOUNT_NAME    => $search_vhost->{account_name} );

    $Template->param( STATIC_HREF => 'http://s.slwifi.com' );
    $Template->param( SEARCH_LOGO => $search_vhost->{search_logo} );

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
