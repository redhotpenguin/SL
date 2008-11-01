package SL::Apache::App::CP;

use strict;
use warnings;


use Apache2::Const -compile => qw(OK SERVER_ERROR NOT_FOUND M_GET M_POST);
use Apache2::Log        ();
use Apache2::SubRequest ();
use Data::FormValidator ();
use Apache2::Request    ();
use Apache2::SubRequest ();

use base 'SL::Apache::App';

use SL::App::Template ();
our $Tmpl = SL::App::Template->template();

# this specific template logic
use Data::Dumper;
use SL::Model;
use SL::Model::App;    # works for now

sub auth {
    my ($class, $r) = @_;

    my %tmpl_data;

    my $output;
    my $ok = $Tmpl->process('auth/index.tmpl', \%tmpl_data, \$output, $r);
    $ok ? return $class->ok($r, $output)
        : return $class->error($r, "Template error: " . $Tmpl->error());
}


sub paid {
    my ($class, $r) = @_;

    my $req = Apache2::Request->new($r);


    my %tmpl_data = ( plan => $req->param('plan'), );



    my $output;
    my $ok = $Tmpl->process('auth/paid.tmpl', \%tmpl_data, \$output, $r);
    $ok ? return $class->ok($r, $output)
        : return $class->error($r, "Template error: " . $Tmpl->error());

}

1;
