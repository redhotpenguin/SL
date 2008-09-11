package SL::User;

use strict;
use warnings;

our $VERSION = 0.02;

use SL::Cache ();
use base 'SL::Cache';

our $CONFIG = SL::Config->new();

sub new {
    my $class = shift;

    my $self = $class->SUPER::new( type => 'raw' );
    return $self;
}

sub set_last_seen {
    my ( $self, $user_id ) = @_;

    # update the cache
    $self->{cache}->set( join( '|', 'user', 'last_seen', $user_id ) => time() );

    return 1;
}

sub get_last_seen {
    my ( $self, $user_id ) = @_;

    my $last_seen =
      $self->{cache}->get( join( '|', 'user', 'last_seen', $user_id ) );
    return unless $last_seen;
    return $last_seen;
}

sub set_last_auth {
    my ( $self, $user_id ) = @_;

    # update the cache
    $self->{cache}->set( join( '|', 'user', 'last_auth', $user_id ) => time() );

    return 1;
}

sub get_last_auth {
    my ( $self, $user_id ) = @_;

    my $last_auth =
      $self->{cache}->get( join( '|', 'user', 'last_auth', $user_id ) );
    return unless $last_auth;
    return $last_auth;
}

1;
