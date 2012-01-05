package SL::Search;

use strict;
use warnings;

=head1 NAME

SL::Search - Handles searches for Silver Lining

=cut

our $VERSION = 0.04;

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

