package SL::HTTP::Request;

use strict;
use warnings;

use base 'HTTP::Request';

sub new {
    my ($class, $args_ref) = @_;
    my $self = $class->SUPER::new($args_ref->{method}, $args_ref->{url});

    foreach my $k ( keys %{$args_ref->{headers}} ) {
            next if (   
                $k eq 'If-Modified-Since'
                or $k eq 'If-None-Match'
                or $k eq 'Accept-Encoding');
            
            $self->header($k => $args_ref->{headers}->{$k});
    }
    return $self;
}

1;