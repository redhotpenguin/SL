package SL::Search;

use strict;
use warnings;

=head1 NAME

SL::Search - Handles searches for Silver Lining virtual hosts

=cut

our $VERSION = 0.02;

use constant SEARCH => 'Yahoo';    # 'Google'

=cut
BEGIN {

    if ( SEARCH eq 'Yahoo' ) {
        require WebService::Yahoo::BOSS;
    }
    elsif ( SEARCH eq 'Google' ) {
        require Google::Search;
    }
}
=cut

use WebService::Yahoo::BOSS;
use Encode ();
use Encode::Guess qw/euc-jp shiftjis 7bit-jis/;
use Data::Dumper qw(Dumper);
use RHP::Timer;

use constant DEBUG => $ENV{SL_DEBUG} || 0;

use Config::SL;

our $Config = Config::SL->new;

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

        my $timer = RHP::Timer->new;
        $timer->start('new yahoo');
        my $boss =
          WebService::Yahoo::BOSS->new( appid => $Config->sl_yahoo_appid );

        warn(sprintf("timer_name: %s, time: %s",
                                          @{$timer->checkpoint}[3,4]));

        $timer->start('search');
        $search = eval { $boss->Web( %{$search_args} ) };
        die $@ if $@;

        warn(sprintf("timer_name: %s, time: %s",
                                          @{$timer->checkpoint}[3,4]));
        
    }
    return $search;
}

sub search {
    my ( $class, $search_args ) = @_;

    my $search = eval { $class->run_search($search_args) };
    die $@ if $@;

    if ( $class->engine eq 'Google' ) {
        $search = $class->process_google_results($search);
    }
    elsif ( $class->engine eq 'Yahoo' ) {

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

            $hash{'content'} = eval { $class->force_utf8( $hash{'content'} ) };
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

