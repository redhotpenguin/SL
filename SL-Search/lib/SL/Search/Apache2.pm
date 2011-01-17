package SL::Search::Apache2;

use strict;
use warnings;

use Apache2::Connection ();
use Apache2::Response   ();
use Apache2::Request    ();
use Apache2::RequestRec ();
use Apache2::RequestIO  ();
use Apache2::Const -compile =>
  qw( SERVER_ERROR DONE OK REDIRECT NOT_FOUND DECLINED );
use Apache2::URI    ();
use Apache2::Cookie ();
use Apache2::Log    ();

use Config::SL     ();
use HTML::Entities ();
use Template       ();
use Data::Dumper qw(Dumper);
use RHP::Timer       ();
use Cache::Memcached ();
use MIME::Base64     ();
use Crypt::CBC       ();
use URI::Escape qw(uri_escape);

use SL::Model::App       ();
use SL::Search           ();
use SL::Search::CityGrid ();


use constant DEBUG         => $ENV{SL_DEBUG}         || 0;
use constant VERBOSE_DEBUG => $ENV{SL_VERBOSE_DEBUG} || 0;
use constant TIMING        => $ENV{SL_TIMING}        || 0;

our $Config = Config::SL->new;

our $Template = Template->new( INCLUDE_PATH => $Config->sl_root . '/tmpl/' );

our $Timer       = RHP::Timer->new();
our $Searchtimer = RHP::Timer->new();

our $Memd = Cache::Memcached->new( { servers => ['127.0.0.1:11211'] } );

our $Cipher = Crypt::CBC->new(
    -key    => $Config->sl_cookie_secret,
    -cipher => 'Blowfish',
);

# root handler - any requests without queries

sub handler {
    my ( $class, $r ) = @_;

    if ($r->uri eq '/robots.txt') {
        $r->content_type('text/plain');
        $r->no_cache(1);
        $r->print("User-agent: *\nDisallow: /");
        return Apache2::Const::OK;
    }

    if (($r->hostname eq 'app.silverliningnetworks.com') or
        ($r->hostname eq 'app.slwifi.com') or
        ( $r->construct_url =~ /https:\/\//)) {

        # redirect to the https side for the app
        $r->headers_out->set( Location => 'https://' . $r->hostname . 
            '/' . $r->args);
        $r->no_cache(1);
        return Apache2::Const::REDIRECT;
    }

    $r->headers_out->set( Location => 'http://'
          . $Config->sl_apache_servername
          . '/search?q=pizza&submit=Search' );
    $r->no_cache(1);
    return Apache2::Const::REDIRECT;
}

# tos handler - new users

sub tos {
    my ( $class, $r ) = @_;

    my $state = $r->pnotes('state');

    $r->log->debug( "tos state: " . Dumper($state) ) if DEBUG;

    my ($user) =
      SL::Model::App->resultset('SearchUser')
      ->search( { uuid => $state->{'uuid'} } );

    unless ($user) {
        $r->log->error( "no user for uuid " . $state->{'uuid'} );
        return Apache2::Const::SERVER_ERROR;
    }
    else {
        $user->tos( time() );
        $user->update;
    }

    $state->{'tos'} = time();

    $class->send_cookie( $r, $state );
    my $output = 'tos accepted, ajax response';

    my $bytes = $class->print_response( $r, $output );

    return Apache2::Const::OK;
}

# handle /search namespace

sub search {
    my ( $class, $r ) = @_;

    $Searchtimer->start('searchtimer');

    my $req = Apache2::Request->new($r);

    my $q = $req->param('q') || 'pizza';

    my $start = $req->param('start') || 0;

    my ($network) =
      SL::Model::App->resultset('Network')
      ->find_or_create( { wan_ip => $r->connection->remote_ip } );

    unless ($network) {
      $r->log->error("no network for ip " . $r->connection->remote_ip);
      return Apache2::Const::SERVER_ERROR;
    }

    my %tmpl_args;

    ################################
    # run the web search
    my $search =
      $Memd->get( sprintf( 'search|%s|%s', uri_escape($q), $start ) );

    unless ($search) {
        $r->log->debug("search cache miss for $q") if DEBUG;

        $search =
          eval { SL::Search->search( { query => $q, start => $start } ); };

        if ($@) {
            $r->log->error("search for '$q' failed: $@");

            #$r->custom_response( Apache2::Const::SERVER_ERROR, $Fivehundred );
            return Apache2::Const::SERVER_ERROR;
        }

        # cache the results
        $Memd->set(
            sprintf( 'search|%s|%s', uri_escape($q), $start ) => $search,
            60
        );

    }

    ################
    # grab the ads
    my $citygrid = $Memd->get( 'citygrid|' . uri_escape($q) );
    my $zip = $network->zip;

    if (!$zip) {

      $r->log->error("missing zip for network " . Dumper($network));

    } elsif (!$citygrid && $zip) {

        $r->log->debug("citygrid cache miss for $q") if DEBUG;

        my $last = $Memd->get('last_citygrid_searchtime')
          || [ 0, 0 ];

        ( $citygrid, $last ) =
          eval { SL::Search::CityGrid->search( $q, $last, $network->zip) };

        if ($@) {
            $r->log->error("no citygrid results for '$q', $@");
            return Apache2::Const::SERVER_ERROR;
        }

        if ($citygrid) {

            $Memd->set(
                sprintf( 'citygrid|%s', uri_escape($q) ) => $citygrid,
                60
            );

            $Memd->set(
                'last_citygrid_searchtime' => $last,
                60
            );
        }
        else {
            $r->log->warn("citygrid search limit exceeded");
        }
    }

    # get search suggestions from cache, or ping google
    my $suggestions = $Memd->get( 'suggestions|' . uri_escape($q) );
    unless ($suggestions) {
        $r->log->debug("suggest cache miss for $q") if DEBUG;
        $suggestions = SL::Search->suggest($q);
        $Memd->set( 'suggestions|' . uri_escape($q) => $suggestions );
    }

    my ( $pkg, $file, $line, $timer_name, $interval ) =
      @{ $Searchtimer->checkpoint };

    ####################
    # render the template
    $q = HTML::Entities::encode_numeric($q);
    my $plus_q = $q;
    $plus_q =~ s/ /\+/g;

    %tmpl_args = (
        query_time     => sprintf( "%1.1f", $interval ),
        q              => $q,
        plusquery      => $plus_q,
        start          => $start,
        suggestions    => $suggestions,
        start_param    => $start + 1,
        finish         => $start + 10,
        cg_ads         => $citygrid,
        search_results => $search,
        template       => 'search.tmpl',
        s_referrer => $req->param('s_referrer') || 'google',
        state => $r->pnotes('state'),
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

    $tmpl_args{'numbers'} = \@numbers;
    $tmpl_args{'state'}   = $r->pnotes('state');


    $tmpl_args{'network'} = $network;
    $r->log->debug("state is " . Dumper($r->pnotes('state'))) if DEBUG;

    my %search_log = (
            network  => $network,
            user     => $r->pnotes('state')->{'uuid'},
            query        => $q,
            start    => $start,
            duration => sprintf( "%1.2f", $interval )
    );

    $r->log->debug(Dumper(\%search_log)) if DEBUG;

    # log data for the loghandler
    $r->pnotes(
        'search_log' => \%search_log );

    my $output = $class->template_process( \%tmpl_args );

    my $bytes = $class->print_response( $r, $output );

    return Apache2::Const::OK;
}

# handles logging searches to the db

sub log_handler {
    my ( $class, $r ) = @_;

    my $search_log = $r->pnotes('search_log');
    my ($user) =
      SL::Model::App->resultset('SearchUser')
      ->search( { uuid => $search_log->{'user'} } );

    my $search = SL::Model::App->resultset('Search')->create(
        {
            network_id  => $search_log->{'network'}->network_id,
            search_user_id     => $user->search_user_id,
            query    => $search_log->{'query'},
            start    => $search_log->{'start'},
            duration => $search_log->{'duration'}
        }
    );

    return Apache2::Const::DECLINED;
}

=item cookie_monster

Handler for cookies

=cut

sub cookie_monster {
    my ( $class, $r ) = @_;

    # see if the user has cookies for this host
    my $j    = Apache2::Cookie::Jar->new($r);
    my $c_in = $j->cookies('SLSearch');

    my $state;
    if ($c_in) {

        $state = $class->decode( $c_in->value );

        unless ( keys %{$state} ) {
            $state = $class->send_new_cookie($r);
        }
    }
    else {
        $state = $class->send_new_cookie($r);
    }

    $r->pnotes( 'state' => $state );

    return Apache2::Const::DECLINED;
}

# sends a new cookie

sub send_new_cookie {
    my ( $class, $r ) = @_;

    my $state = $class->default_state($r);

    $class->send_cookie( $r, $state );

    return $state;
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

    $args->{perlbal_listen} = $Config->sl_apache_servername;
    $args->{static_host}    = $Config->sl_static_host;

      my $output;
    $Template->process( $args->{'template'}, $args, \$output )
      || die $Template->error;

    return $output;
}

sub expire_cookie {
    my ( $class, $r ) = @_;

    my $cookie = Apache2::Cookie->new(
        $r,
        -name    => 'SLSearch',
        -value   => '',
        -expires => 'Mon, 21-May-1971 00:00:00 GMT',
        -path    => '/',
    );

    $cookie->bake($r);
    return 1;
}

sub encode {
    my ( $class, $state ) = @_;

    my $joined = join(
        ':', map { join( ':', $_, $state->{$_} ) }
          keys %{$state}
    );
    return $Cipher->encrypt($joined);
}

sub decode {
    my ( $class, $val ) = @_;
    my $decrypted = $Cipher->decrypt($val);
    my %state = split( ':', $decrypted );
    return \%state;
}

sub send_cookie {
    my ( $class, $r, $state ) = @_;

    my $cookie = Apache2::Cookie->new(
        $r,
        -name  => 'SLSearch',
        -value => $class->encode($state),

        #     -expires => '60s',
        -expires => '+10Y',
    );
    $cookie->path('/');
    $cookie->bake($r);
}

sub default_state {
    my ( $class, $r ) = @_;

    my $client_ip = $r->connection->remote_ip;

    my $user =
      SL::Model::App->resultset('SearchUser')
      ->create( { user_agent => $r->headers_in->{'User-Agent'}, } );

    my %state = ( tos => 0, uuid => $user->uuid );
    $r->log->debug( "new cookie state: " . Dumper( \%state ) ) if DEBUG;

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
