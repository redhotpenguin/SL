package SL::Search::Apache2

use strict;
use warnings;

use Apache2::Connection ();
use Apache2::Response   ();
use Apache2::Request    ();
use Apache2::RequestRec ();
use Apache2::RequestIO  ();
use Apache2::Const -compile => qw( SERVER_ERROR DONE OK REDIRECT NOT_FOUND );
use Apache2::URI ();

use Apache2::Cookie ();

use SL::Config ();
use SL::Search ();

use HTML::Entities ();
use Template       ();
use Data::Dumper qw(Dumper);
use RHP::Timer                   ();
use WebService::CityGrid::Search ();
use Cache::Memcached             ();
use MIME::Base64                 ();
use Crypt::CBC                   ();

use constant DEBUG         => $ENV{SL_DEBUG}         || 0;
use constant VERBOSE_DEBUG => $ENV{SL_VERBOSE_DEBUG} || 0;
use constant TIMING        => $ENV{SL_TIMING}        || 0;

our $Config = SL::Config->new;

our $Template = Template->new( INCLUDE_PATH => $Config->sl_root . '/tmpl/' );

our $Timer       = RHP::Timer->new();
our $Searchtimer = RHP::Timer->new();

our $Memd = Cache::Memcached->new( { servers => ['127.0.0.1:11211'] } );

our $Cipher = Crypt::CBC->new(
    -key    => $Config->sl_cookie_secret,
    -cipher => 'Blowfish',
);

sub search {
    my ( $class, $r ) = @_;

    my $req = Apache2::Request->new($r);


    my @search_results;
    my $q = $req->param('q');
    my $start = $req->param('start') || 0;
    my %tmpl_args = ( static_host => $Config->sl_static_host );



    # if we have a query
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

            #$r->custom_response( Apache2::Const::SERVER_ERROR, $Fivehundred );
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
        if ( $time - $last_search > 0 ) {

            # ok to run a new search
            $Memd->set( 'last_citygrid_searchtime' => $time );
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
                next unless $cg_result->neighborhood;
                last if ++$i == 3;

                if ( $i == 1 ) {
                    $cg_result->top_hit(1);
                }
                push @refined, $cg_result;
            }

            if (@refined) {
                $Template->param( CG_ADS => \@refined );
            }
        }

        $q = HTML::Entities::encode_numeric($q);
        $r->log->debug("Start is $start");
        my $plus_q = $q;
        $plus_q =~ s/ /\+/g;

        %tmpl_args = (
            query_time  => sprintf( "%1.2f", $interval ),
            query       => $q,
            plusquery   => $plus_q,
            start       => $start,
            start_param => $start + 1,
            finish      => $start + 10,
        );

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
        else {
            if ( $start < 50 ) {
                $tmpl_args{'next'} = 0;
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

            $tmpl_args{'numbers'}        = \@numbers;
            $tmpl_args{'search_results'} = $search_results;

            $tmpl_args{'sideadcode'} = $search_vhost->{adserver_side};
            $tmpl_args{'template'}   = 'results.tmpl';
        }

    }
    else {

        # serve the blank search page
        $tmpl_args{'template'} = 'search.tmpl';

    }
    $tmpl_args{'account_website'} = $search_vhost->{account_website};
    $tmpl_args{'account_name'}    = $search_vhost->{account_name};

    $tmpl_args{'static_href'} = 'http://s.slwifi.com';
    $tmpl_args{'search_logo'} = $search_vhost->{search_logo};

    $tmpl_args{'last_seen'}      = $last_seen;
    $tmpl_args{'closed_message'} = $closed_message;

    $r->content_type('text/html; charset=UTF-8');
    $r->no_cache(1);
    $r->rflush;

    my $output;
    $r->log->debug( "template args: " . Dumper( \%tmpl_args ) ) if DEBUG;
    $Template->process( $tmpl_args{'template'}, \%tmpl_args, \$output )
      || die $Template->error;
    $r->print($output);

    return Apache2::Const::OK;
}

sub close_message {
    my ( $class, $r ) = @_;

    # see if the user has cookies for this host
    my $j    = Apache2::Cookie::Jar->new($r);
    my $c_in = $j->cookies('SLSearch');

    my ( $last_seen, $closed_message );
    unless ($c_in) {    # read their cookie

        $r->log->error("no cookie no close message");
        return Apache2::Const::NOT_FOUND;
    }

    my %state = $class->decode( $c_in->value );
    unless ( keys %state ) {
        $r->log->error(
            "malformed cookie: $c_in for ip " . $r->connection->remote_ip );
        return Apache2::Const::SERVER_ERROR;
    }
    $state{closed_message} = time;
    $class->send_cookie( $r, \%state );
    return Apache2::Const::OK;
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

=item cookie_monster

A postreadrequest handler that sets cookies

=cut

sub cookie_monster {
    my ($class, $r) = @_;

    # figure out what vhost we are
    my $hostname = $r->hostname;
    $r->log->debug(
        "handling host $hostname, client " . $r->connection->remote_ip )
      if DEBUG;

    # hack
    if ( $hostname eq 'app.silverliningnetworks.com' ) {

        # redirect this app server request
        $r->headers_out->set( Location => "https://$hostname/" );
        return Apache2::Const::REDIRECT;
    }

    # figure out what virtual host we are
    my $search_vhost = SL::Search->vhost( { host => $r->hostname } )
        || SL::Search->default_vhost;

    # see if the user has cookies for this host
    my $j    = Apache2::Cookie::Jar->new($r);
    my $c_in = $j->cookies('SLSearch');

    my ( $last_seen, $closed_message );
    if ($c_in) {    # read their cookie

        my %state = $class->decode( $c_in->value );
        unless ( keys %state ) {
            $r->log->error(
                "malformed cookie: $c_in for ip " . $r->connection->remote_ip );
            return Apache2::Const::SERVER_ERROR;
        }
        $state{last_seen} = $last_seen = time;
        $class->send_cookie( $r, \%state );
        $r->pnotes('closed_message') = $state{closed_message};
    }
    else {          # give them a new cookie
        $r->log->debug("issuing new cookie") if DEBUG;

        $last_seen = 0;
        my %state = (
            ip    => $r->connection->remote_ip,
            vhost => $r->hostname,
        );
        $class->send_cookie( $r, \%state );
    }

    return Apache2::CONST::DECLINED;
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
