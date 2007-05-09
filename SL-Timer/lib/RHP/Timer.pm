package SL::Timer;

use strict;
use warnings;

use Time::HiRes ();

sub new {
    my ($class) = @_;
    my $self = {};
    bless $self, $class;
    return $self;
}

sub start {
    my ($self, $name) = @_;
    $self->{$name}->{_start} = [Time::HiRes::gettimeofday];
    $self->{_current} = $name;
    return $self;
}

sub stop {
    my ($self) = @_;
    no strict 'refs';
    $self->{$self->{_current}}->{_stop} = [Time::HiRes::gettimeofday];
    $self->{$self->{_current}}->{interval} =
      Time::HiRes::tv_interval($self->{$self->{_current}}->{_start},
                               $self->{$self->{_current}}->{_stop});
    return $self->{$self->{_current}}->{interval};
}

sub current {
    my $self = shift;
    return $self->{_current};
}

1;
