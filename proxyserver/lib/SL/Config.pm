package SL::Config;

use strict;
use warnings;

my $cfg;

sub new {
	my ($class, $args) = @_;
	$cfg = {};
	bless $cfg, $class;
	$cfg->_init(@_);

	return $cfg;
}

sub cfg {
	my $self = shift;
	return $self->{_config};
}

sub init {
	my ($self, $args_ref) = @_;

	foreach my $key ( keys %{$args_ref} ) {
		$self->{_config}->{$key} = $args_ref->{$key};
	}
}

sub data_root {
	my $self = shift;
	return join('/', $self->{_config}->{root}, $self->{_config}->{version}, 
					 $self->{_config}->{server}, 'data');
}

1;