package SL::HTTP::Request;

use strict;
use warnings;

use base 'HTTP::Request';

our $VERSION = 0.02;

sub new {
    my ($class, $args_ref) = @_;

    my $self = $class->SUPER::new($args_ref->{method}, $args_ref->{url});

    # copy the headers to the request
    foreach my $k (keys %{$args_ref->{headers}}) {
        next
          if (   $k eq 'If-Modified-Since'
              or $k eq 'If-None-Match' );

        $self->header($k => $args_ref->{headers}->{$k});
    }
	$self->protocol('HTTP/1.1');
	return $self;
}

1;
