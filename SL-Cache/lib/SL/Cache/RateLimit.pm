package SL::Cache::RateLimit;

use strict;
use warnings;

use SL::Cache ();
use base 'SL::Cache';

our $CONFIG     = SL::Config->new();
our $RATE_LIMIT = $CONFIG->sl_proxy_rate_limit;

sub new {
    my $class = shift;

    my $self = $class->SUPER::new( type => 'raw');
    return $self;
}

=head1 NAME

SL::Cache::RateLimit - cache based rate-limit enforcement for ad serving

=head1 SYNOPSIS

  $rate_limit = SL::Cache::RateLimit->new;

  # determine if this request is over the limit
  $is_too_fast = $rate_limit->check_violation(
      $ip, $user_agent );

  # record an ad served
  $rate_limit->record_ad_serve( $ip, $user_agent );

  if ($rate_limit->check_violation( $ip, $user_agent )) {
    # don't serve an ad
  }

=head1 DESCRIPTION

This module is responsible for enforcing a rate-limit on ad-serving to
a unique client.  This is useful for preventing multiple ads from
appearing on a page when other methods fail.

The rate limit is controlled by the sl_proxy_rate_limit directive in
sl.conf:

  sl_proxy_rate_limit '10 sec'

Speaking generally, larger values will provide better protection against 
seeing multiple ads on a page but will miss more chances to show ads when
users click through links quickly or open multiple pages
simultaneously.

=head1 METHODS

=over 4

=item record_ad_serve

  $rate_limit->record_ad_serve( $ip, $user_agent );

Records an ad being served.

=item check_violation

  $is_toofast = $rate_limit->check_violation( $ip, $user_agent);

Checks to see if this request is over the limit for the user.  Returns
1 for violations, 0 for no violation.

=cut

sub record_ad_serve {
    my ( $self, $ip, $user_agent ) = @_;

    my $user_id = _user_id( $ip, $user_agent );

    # update the cache
    $self->{cache}->set( join('|', 'ratelimit', $user_id) => time() );

    return 1;
}

sub _user_id {
    my ( $ip, $user_agent ) = @_;
    return join ( '|', $ip, $user_agent );
}

sub check_violation {
    my ( $self, $ip, $user_agent ) = @_;

    # Determine a maximally unique ID which will hopefully reliably
    # identify a user.  We can't use cookies due to the multi-domain
    # nature of SL
    # FIX: add the user's IP or MAC address (not possible without help
    # from the router)
    my $user_id = _user_id( $ip, $user_agent );

    # do the rate check with limit
    my $last_known = $self->{cache}->get(join('|', 'ratelimit', $user_id));
    return unless $last_known;

    ( ( time() - $last_known ) < $RATE_LIMIT ) ? return 1 : return;
}

1;
