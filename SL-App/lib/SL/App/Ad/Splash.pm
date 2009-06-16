package SL::App::Ad::Splash;

use strict;
use warnings;

use Apache2::Const -compile =>
  qw(OK SERVER_ERROR NOT_FOUND REDIRECT M_GET M_POST);
use Apache2::Log        ();
use Apache2::SubRequest ();
use Apache2::Request    ();
use Apache2::SubRequest ();

use base 'SL::App';

use SL::Model         ();
use SL::Model::App    ();
use SL::App::Template ();
use Data::Dumper;
use Digest::MD5 ();

our $Tmpl = SL::App::Template->template();

use constant DEBUG => $ENV{SL_DEBUG} || 0;
use constant SALT => 69 * 420;

sub dispatch_index {
    my ( $self, $r ) = @_;

    my $output;
    $Tmpl->process(
        'ad/splash/index.tmpl',
        {
            link => $r->construct_url(
                '/splash/'
                  . Digest::MD5::md5_hex(
                    SALT + $r->pnotes( $r->user )->account->account_id
                  )
            ),
        },
        \$output,
        $r
    ) || return $self->error( $r, $Tmpl->error );

    return $self->ok( $r, $output );
}


sub dispatch_splash {
    my ($class, $r) = @_;

    my $path = $r->path_info;
    $path = substr($path, 1, length($path)-1);

    $r->log->debug("md5sum is " . $path) if DEBUG;

    # you might think I'm crazy
    # but I'm just lazy
    # and this may be faster than a database search for i < 10001
    my $i = 1;
    while ($i <= 10000) {
      last unless Digest::MD5::md5_hex(SALT+$i) eq $path;
    }

    $r->log->debug("account is is $i") if DEBUG;

    my $ip = $r->connection->remote_ip;

    my ($loc) = SL::Model::App->resultset('Location')->search({ ip => $ip });
    unless ($loc) {
      $r->log->error("no registered location for ip $ip");
      return Apache2::Const::NOT_FOUND;
    }

    my ($router) =
          sort { $b->mts cmp $a->mts }
          map { $_->router } $loc->router__locations;

    unless ($router) {
      $r->log->error("no registered router for ip $ip");
      return Apache2::Const::NOT_FOUND;
    }

    $r->log->debug("router is $router") if DEBUG;

    # yay we have a router, get a random splash ad
    my @adzones = SL::Model::App->resultset('AdZone')->search(
            { 'router__ad_zones.router_id' => $router->router_id,
             'ad_size.grouping' => 3 },
            { join => [ qw( ad_size router__ad_zones ) ] },);

    my $rand = $adzones[int(rand(scalar(@adzones)-1))];

    my $output  = $rand->code;
    return $class->ok($r, $output);
}



1;
