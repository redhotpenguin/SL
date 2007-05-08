package TestSL::01methods;

use Apache::Test qw(-withtestmore);
use Apache2::Const -compile => qw(OK);

sub handler {
	my $r = shift;
	plan $r, tests => 1;
	{
		use_ok('SL::Apache');
	}

	return Apache2::Const::OK
}
1;