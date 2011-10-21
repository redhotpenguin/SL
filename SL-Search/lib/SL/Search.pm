package SL::Search;

use strict;
use warnings;

=head1 NAME

SL::Search - Handles searches for Silver Lining

=cut

our $VERSION = 0.03;

use Google::Search ();
use WebService::Yahoo::BOSS;

use constant DEBUG => $ENV{SL_DEBUG} || 0;

use Config::SL;
our $Config = Config::SL->new;

our $Boss = WebService::Yahoo::BOSS->new( ckey => $Config->sl_ckey, csecret => $Config->sl_csecret );

# search the web

sub search {
    my ( $class, $search_args ) = @_;

    my $search = eval { $Boss->Web( %{$search_args} ) };
    die $@ if $@;

    return $search;
}

# search suggestions

sub suggest {
    my ( $class, $term ) = @_;
    my $suggestions = Google::Search->suggest($term);

    my @ranked = map { $_->[0] } sort { $a->[2] cmp $b->[2] } @{$suggestions};

    return \@ranked;
}


1;

=head1 SYONPSIS


=head1 DESCRIPTION

Does searching.

=head1 AUTHOR

Fred Moyer <fred@slwifi.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Silver Lining Networks.

This software is proprietary under the Silver Lining Networks software license.

=cut

