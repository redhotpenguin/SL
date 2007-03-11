package SL::Model::RateLimit;

use strict;
use warnings;

use SL::Model;
use SL::Config;
use Params::Validate qw(validate);

=head1 NAME

SL::Model::RateLimit - rate-limit enforcement for ad serving

=head1 SYNOPSIS

  my $rate_limit = SL::Model::RateLimit->new(r => $r);

  # record an ad served
  $rate_limit->record_ad_serve();

  # determine if this request is over the limit
  if ($rate_limit->check_violation()) {
    # don't serve an ad
  }

=head1 DESCRIPTION

This module is responsible for enforcing a rate-limit on ad-serving to
a unique client.  This is useful for preventing multiple ads from
appearing on a page when other methods fail.

The rate limit is controlled by the sl_proxy_rate_limit directive in
sl.conf:

  sl_proxy_rate_limit '10 sec'

The value must be a valid Postgres interval value.  Speaking
generally, larger values will provide better protection against seeing
multiple ads on a page but will miss more chances to show ads when
users click through links quickly or open multiple pages
simultaneously.

Individual routers can have custom rate-limits by setting
router.custom_rate_limit.

=head1 METHODS

=over 4

=item new

  my $rate_limit = SL::Model::RateLimit->new(r => $r);

Create a new rate limit object.  Requires the Apache request object as
a named param called 'r'.

=item record_ad_serve

  $rate_limit->record_ad_serve();

Records an ad being served.

=item check_violation

  $is_toofast = $rate_limit->check_violation();

Checks to see if this request is over the limit for the user.  Returns
1 for violations, 0 for no violation.

=cut

sub new {
    my $pkg  = shift;
    my %args = validate(@_, { r => { isa => 'Apache2::RequestRec' } });

    my $self = bless \%args, $pkg;

    $self->{user_id} = $self->_bake_user_id();

    return $self;
}

# Determine a maximally unique ID which will hopefully reliably
# identify a user.  We can't use cookies due to the multi-domain
# nature of SL
sub _bake_user_id {
    my $self = shift;
    my $r    = $self->{r};

    # start with the router's IP
    my $uid = $r->connection->remote_ip;

    # FIX: add the user's IP or MAC address (not possible without help
    # from the router)

    # add in user-agent
    $uid .= "|" . $r->headers_in->{'user-agent'};

    # trim to max-length of 150 to fit in table - truncating the
    # user-agent is ok
    $uid = substr($uid, 0, 150) if length($uid) > 150;

    return $uid;
}

sub record_ad_serve {
    my $self = shift;
    my $dbh = SL::Model->connect();
    my $user_id = $self->{user_id};

    # try an update, will fail if this user's not in the rate_limit
    # table yet
    my $update_sth = 
      $dbh->prepare_cached('UPDATE rate_limit SET ts = NOW() 
                            WHERE user_id = ?');
    my $ok = $update_sth->execute($user_id);

    # insert if update didn't work (when it fails it's 0E0, zero but true!)
    if ($ok == 0) {
        my $insert_sth = 
          $dbh->prepare_cached('INSERT INTO rate_limit (user_id) VALUES (?)');
        $insert_sth->execute($user_id);
    }
}

sub check_violation {
    my $self = shift;
    my $dbh = SL::Model->connect();
    my $user_id = $self->{user_id};
    my $r = $self->{r};

    # check for a custom rate-limit for this router
    my $custom_limit_sth = 
      $dbh->prepare_cached('SELECT custom_rate_limit FROM router 
                            WHERE ip = ?');
    $custom_limit_sth->execute($r->connection->remote_ip);
    my ($limit) = $custom_limit_sth->fetchrow_array();

    # use the global limit if none set
    unless ($limit) {
        $limit = $r->dir_config('SLRateLimit');
    }

    # do the rate check with limit
    my $check_sth = 
      $dbh->prepare_cached('SELECT 1 FROM rate_limit 
                            WHERE user_id = ? AND (now() - ts) < ?');
    $check_sth->execute($user_id, $limit);
    my ($violation) = $check_sth->fetchrow_array();

    return $violation ? 1 : 0;
}

1;
