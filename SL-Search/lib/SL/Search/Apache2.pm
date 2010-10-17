package SL::Search::Apache2;

use strict;
use warnings;

use base 'SL::Search';

use Apache2::Connection ();
use Apache2::Response   ();
use Apache2::Request    ();
use Apache2::RequestRec ();
use Apache2::RequestIO  ();
use Apache2::Const -compile =>
  qw( SERVER_ERROR DONE OK REDIRECT NOT_FOUND DECLINED );
use Apache2::URI    ();
use Apache2::Cookie ();

use Config::SL     ();
use HTML::Entities ();
use Template       ();
use Data::Dumper qw(Dumper);
use RHP::Timer                   ();
use WebService::CityGrid::Search ();
use Cache::Memcached             ();
use MIME::Base64                 ();
use Crypt::CBC                   ();

#use SL::Network ();

use constant DEBUG         => $ENV{SL_DEBUG}         || 0;
use constant VERBOSE_DEBUG => $ENV{SL_VERBOSE_DEBUG} || 0;
use constant TIMING        => $ENV{SL_TIMING}        || 0;

use constant CITYGRID_MAX_RATE => 2;    # queries per second

our $Config = Config::SL->new;

our $Template = Template->new( INCLUDE_PATH => $Config->sl_root . '/tmpl/' );

our $Timer       = RHP::Timer->new();
our $Searchtimer = RHP::Timer->new();

our $Memd = Cache::Memcached->new( { servers => ['127.0.0.1:11211'] } );

our $Cipher = Crypt::CBC->new(
    -key    => $Config->sl_cookie_secret,
    -cipher => 'Blowfish',
);

our $Cg = WebService::CityGrid::Search->new(
    api_key   => $Config->sl_citygrid_api_key,
    publisher => $Config->sl_citygrid_publisher,
);

# root handler - any requests without queries

sub handler {
    my ( $class, $r ) = @_;

    $r->headers_out->set( Location => 'http://'
          . $Config->sl_perlbal_listen
          . '/search?q=pizza&submit=Search' );
    $r->no_cache(1);
    return Apache2::Const::REDIRECT;
}

# tos handler - new users

sub tos {
    my ( $class, $r ) = @_;

    my %state = %{ $r->pnotes('state') };
    $state{'tos'} = time();
    $class->send_cookie( $r, \%state );
    my $output = 'tos accepted, ajax response';

    my $bytes = $class->print_response( $r, $output );

    return Apache2::Const::OK;
}

# handle /search namespace

sub search {
    my ( $class, $r ) = @_;

    my $req = Apache2::Request->new($r);

    my $q = $req->param('q') || 'pizza';

    my $start = $req->param('start') || 0;
    my %tmpl_args;

    $Searchtimer->start('searchtimer');

    my %search_args = (
        query     => $q,
        start     => $start,
        s_referrer => $req->param('s_referrer') || 'google',
        url       => $r->construct_url( $r->unparsed_uri ),
        remote_ip => $r->connection->remote_ip,
        referrer  => $r->headers_in->{'Referer'} || 'http://search.slwifi.com'
    );

    my $search_results = eval { $class->SUPER::search( \%search_args ); };
    if ($@) {
        $r->log->error(
            sprintf(
                "Search for %s failed err '%s'",
                Dumper( \%search_args ), $@
            )
        );

        #$r->custom_response( Apache2::Const::SERVER_ERROR, $Fivehundred );
        return Apache2::Const::SERVER_ERROR;
    }

    my ( $pkg, $file, $line, $timer_name, $interval ) =
      @{ $Searchtimer->checkpoint };

    $r->log->debug( Dumper($search_results) ) if VERBOSE_DEBUG;

    my $citygrid_results = eval { $class->citygrid_results( $q ) };
    if ($@) {
        $r->log->error("no citygrid results: " . $@);
    }

    $q = HTML::Entities::encode_numeric($q);
    my $plus_q = $q;
    $plus_q =~ s/ /\+/g;

    %tmpl_args = (
        query_time     => sprintf( "%1.2f", $interval ),
        q              => $q,
        plusquery      => $plus_q,
        start          => $start,
        start_param    => $start + 1,
        finish         => $start + 10,
        cg_ads         => $citygrid_results,
        search_results => $search_results,
        template       => 'search.tmpl',
        search_engine  => $class->engine,
        state          => $r->pnotes('state'),
    );

    # figure out previous and next buttons
    if ( $start > 9 ) {
        $tmpl_args{'prev'}       = 1;
        $tmpl_args{'prev_start'} = $start - 10;
    }
    else {
        $tmpl_args{'prev'} = 0;
    }

    if ( $start < 50 ) {
        $tmpl_args{'next'} = $start + 10;
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

    $tmpl_args{'numbers'}    = \@numbers;
    $tmpl_args{'sideadcode'} = 'sidebar ads';
    $tmpl_args{'state'}      = $r->pnotes('state');

#    $tmpl_args{'network'} = SL::Network->new( ip => $r->connection->remote_ip );

    my $output = $class->template_process( \%tmpl_args );

    my $bytes = $class->print_response( $r, $output );

    return Apache2::Const::OK;
}

sub citygrid_results {
    my ( $class, $q ) = @_;

    # ping the cache to see if there are recent
    my $citygrid_results =
      $Memd->get( 'citigrid_search|' . URI::Escape::uri_escape($q) );
use Data::Dumper;
    if ($citygrid_results) {
        warn("cache hit, results " . Dumper($citygrid_results));
        return $citygrid_results;

    }
    else {

        # nothing in the cache. run a new query within the rate
        # global rate limit for cg searches

        # last citygrid search time
        my $last_citysearch = $Memd->get('last_citygrid_searchtime')
          || [ 0, 0 ];

        if ( Time::HiRes::tv_interval( $last_citysearch,
            [Time::HiRes::gettimeofday] ) >
            ( 1 / CITYGRID_MAX_RATE ) )
        {
        warn("query limit ok, running query");

            my @citygrid_results;
            my $cg_query = eval { $Cg->query(
                {
                    mode  => 'locations',
                    where => $Config->sl_citygrid_where,
                    what  => URI::Escape::uri_escape($q),
                }
            ) };
            die $@ if $@;

            # mark the last search time
            $Memd->set( 'last_citygrid_searchtime' => time() );

            my $i = 0;
            foreach my $cg_result ( @{$cg_query} ) {
                next unless $cg_result->neighborhood;
                last if ++$i == 4;

                if ( $i == 1 ) {
                    $cg_result->top_hit(1);
                }
                push @citygrid_results, $cg_result;
            }

            # cache the results
            $Memd->set( 'citigrid_search|'
                  . URI::Escape::uri_escape($q) => \@citygrid_results );

            # and return
            return \@citygrid_results;

        } # end result search
        else {

            die "exceeded citygrid query rate: " . CITYGRID_MAX_RATE;
        }

    } # end global rate check

}

=item cookie_monster

Handler for cookies

=cut

sub cookie_monster {
    my ( $class, $r ) = @_;

    # see if the user has cookies for this host
    my $j    = Apache2::Cookie::Jar->new($r);
    my $c_in = $j->cookies('SLSearch');

    my %state;
    if ($c_in) {

        %state = $class->decode( $c_in->value );
        unless ( keys %state ) {

            %state = %{ $class->default_state($r) };
            $class->send_cookie( $r, \%state );
        }

    }
    else {

        %state = %{ $class->default_state($r) };
        $class->send_cookie( $r, \%state );
    }

    $r->pnotes( 'state' => \%state );

    return Apache2::Const::DECLINED;
}

sub print_response {
    my ( $class, $r, $response ) = @_;

    $r->content_type('text/html; charset=UTF-8');
    $r->no_cache(1);
    $r->rflush;

    # return the number of bytes printed
    return $r->print($response);
}

sub template_process {
    my ( $class, $args ) = @_;

    $args->{perlbal_listen} = $Config->sl_perlbal_listen;
    $args->{static_host}    = $Config->sl_static_host,

      my $output;
    $Template->process( $args->{'template'}, $args, \$output )
      || die $Template->error;

    return $output;
}

sub expire_cookie {
    my ( $class, $r ) = @_;

    my $cookie = Apache2::Cookie->new(
        $r,
        -name    => $Config->sl_app_cookie_name,
        -value   => '',
        -expires => 'Mon, 21-May-1971 00:00:00 GMT',
        -path    => $Config->sl_app_base_uri . '/app/',
    );

    $cookie->bake($r);
    return 1;
}

sub encode {
    my ( $class, $state_hashref ) = @_;

    my $joined = join( ':',
        map { join( ':', $_, $state_hashref->{$_} ) }
          keys %{$state_hashref} );
    return $Cipher->encrypt($joined);
}

sub decode {
    my ( $class, $val ) = @_;
    my $decrypted = $Cipher->decrypt($val);
    return split( ':', $decrypted );
}

sub send_cookie {
    my ( $class, $r, $state ) = @_;

    my $cookie = Apache2::Cookie->new(
        $r,
        -name  => 'SLSearch',
        -value => $class->encode($state),

        #     -expires => '60s',
        -expires => '+1M',
    );
    $cookie->path('/');
    $cookie->bake($r);
}

sub default_state {
    my ( $class, $r ) = @_;

    my %state = (
        ip         => $r->connection->remote_ip,
        last_query => undef,
        tos        => 0,
    );

    return \%state;
}

1;

__END__

=head1 SYNOPSIS

  PerlResponseHandler SL::Search::Apache2

=head1 DESCRIPTION

Does searching.

=head1 AUTHOR

Fred Moyer <fred@slwifi.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2010 by Silver Lining Networks.

This software is proprietary under the Silver Lining Networks software license.

=cut
