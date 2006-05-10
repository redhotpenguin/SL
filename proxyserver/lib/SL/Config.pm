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
	if ( ! defined $cfg ) {
		$cfg = __PACKAGE__->new;
	}
	return $cfg;	
}

sub init {
	my ($self, $args_ref) = @_;

	foreach my $key ( keys %{$args_ref} ) {
		$self->{_config}->{$key} = $args_ref->{$key};
	}
}

1;