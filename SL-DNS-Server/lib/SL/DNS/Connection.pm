packet SL::DNS::Connection;

use strict;
use warnings;

use base 'Danga::Socket';

sub new {
  my SL::DNS::Connection $self = shift;
  my $sock = shift;

  $self = fields::new($self) unless ref($self);

  $self->SUPER::new($sock);

  return $self;
}

sub event_read {
  my SL::DNS::Connection $self = shift;

  print "conn event read\n";

  return 1;
}

1;
