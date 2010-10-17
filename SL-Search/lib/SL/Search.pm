package SL::Search;

use strict;
use warnings;

=head1 NAME

SL::Search - Handles searches for Silver Lining

=cut

our $VERSION = 0.02;

use constant SEARCH => 'Yahoo';    # 'Google'

use WebService::Yahoo::BOSS;
use Encode ();
use Encode::Guess qw/euc-jp shiftjis 7bit-jis/;
use Data::Dumper qw(Dumper);
use Cache::Memcached;

use constant DEBUG => $ENV{SL_DEBUG} || 0;

use Config::SL;

our $Config = Config::SL->new;

our $Memd = Cache::Memcached->new( { servers => ['127.0.0.1:11211'] } );

sub engine {
    return SEARCH;
}

sub run_search {
    my ( $class, $search_args ) = @_;

    my $remote_ip = delete $search_args->{remote_ip};
    my $url       = delete $search_args->{url};

    my $search;
    if ( $class->engine eq 'Google' ) {

        $search_args->{key}      = $Config->sl_gsearch_key;
        $search_args->{referrer} = $Config->sl_gsearch_referrer;
        $search = eval { Google::Search->Web( %{$search_args} ); };
        die $@ if $@;
    }
    elsif ( $class->engine eq 'Yahoo' ) {

        my $boss =
          WebService::Yahoo::BOSS->new( appid => $Config->sl_yahoo_appid );

        $search = eval { $boss->Web( %{$search_args} ) };
        die $@ if $@;

    }
    return $search;
}

sub search {
    my ( $class, $search_args ) = @_;

    my $q            = $search_args->{'query'};
    my $start        = $search_args->{'start'};
    my $search_cache = $Memd->get(
        sprintf( 'search|%s|%s', URI::Escape::uri_escape($q), $start ) );

    if ($search_cache) {
        warn("cache hit for '$q'") if DEBUG;
        return $search_cache;
    }
    else {
        warn("cache miss for '$q'") if DEBUG;
    }

    my $search = eval { $class->run_search($search_args) };
    die $@ if $@;

    # cache the results
    $Memd->set(
        sprintf( 'search|%s|%s', URI::Escape::uri_escape($q), $start ) =>
          $search);

          if ( $class->engine eq 'Google' ) {
            $search = $class->process_google_results($search);
        }
        elsif ( $class->engine eq 'Yahoo' ) {

            # no-op
        }

        return $search;
    }

    sub process_google_results {
        my ( $class, $search ) = @_;

        my $i     = 1;
        my $limit = 10;
        my @search_results;
        while ( my $result = $search->next ) {

            warn( "search result: " . Dumper($result) ) if DEBUG;

            last if ++$i > $limit;
            my %hash = map { $_ => $result->{_content}->{$_} }
              keys %{ $result->{_content} };

            if ( defined $hash{'content'} ) {
                my $content = $hash{'content'};

                $hash{'content'} =
                  eval { $class->force_utf8( $hash{'content'} ) };
                warn($@) if ( $@ && DEBUG );
            }

            my $title = $hash{'title'};
            if ( defined $hash{'title'} ) {
                $hash{'title'} = eval { $class->force_utf8( $hash{'title'} ) };
                warn($@) if ( $@ && DEBUG );
            }

            unless ( $hash{'visibleUrl'} =~ m{/} ) {

                $hash{'visibleUrl'} .= '/';
            }

            $hash{'url'} = $hash{'unescapedUrl'};

            push @search_results, \%hash;
        }

        return \@search_results;
    }

    sub force_utf8 {
        my ( $class, $string ) = @_;

        if ( ref( Encode::Guess::guess_encoding($string) ) ) {

            $string = eval { Encode::Guess::decode( "Guess", $string, 0 ) };
            if ($@) {
                die("could not guess decode for $string");
            }
        }
        else {

            $string = Encode::decode( 'utf8', $string, 0 );
            if ($@) {
                die("could not decode utf8 for $string");
            }
        }

        return $string;
    }
    1;

=head1 SYNOPSIS

 $search_vhost = SL::Search->vhost({ host => "search.urbanwireless.net" });

=head1 DESCRIPTION

Does searching.

=head1 AUTHOR

Fred Moyer <fred@slwifi.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2010 by Silver Lining Networks.

This software is proprietary under the Silver Lining Networks software license.

=cut

