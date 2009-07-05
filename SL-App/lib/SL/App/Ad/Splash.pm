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

    my $reg = $r->pnotes( $r->user );

    # get the ad zones this user has access to
    my @ad_zones =
      sort { $b->{router_count} <=> $a->{router_count} }
      sort { $b->mts cmp $a->mts }
      sort { $a->name cmp $b->name } $reg->get_splash_zones;

    #$r->log->debug( "ad zones: " . Dumper( \@ad_zones ) ) if DEBUG;

    $_->mts( $self->sldatetime( $_->mts ) ) for @ad_zones;

    my $link = $r->construct_url(
                '/splash/'
                  . Digest::MD5::md5_hex(
                    SALT + $r->pnotes( $r->user )->account->account_id));


    my %tmpl_data = (
        link => $link,
        ad_zones => \@ad_zones,
        count    => scalar(@ad_zones),
    );




    my $output;
    $Tmpl->process( 'ad/splash/index.tmpl', \%tmpl_data, \$output, $r)
        || return $self->error( $r, $Tmpl->error );

    return $self->ok( $r, $output );
}



sub dispatch_add {
    my ( $self, $r ) = @_;

    my $req = Apache2::Request->new($r);
    my $reg = $r->pnotes( $r->user );

    if ( $r->method_number == Apache2::Const::M_GET ) {

        my $ad_zone = SL::Model::App->resultset('AdZone')->create(
            {
                name       => 'New Splash Page Ad',
                account_id => $reg->account_id,
                reg_id     => $reg->reg_id,
                ad_size_id => 15, # IAB Medium Rectangle
                code       => '',
                active     => 1,
                is_default => 0,
                image_href => ' ',
                link_href => ' ',
            }
        );
        return Apache2::Const::NOT_FOUND unless $ad_zone;
        $ad_zone->update;

        return $self->dispatch_edit( $r, { req => $req }, $ad_zone );

    }

}



sub dispatch_edit {
    my ( $self, $r, $args_ref, $ad_zone_obj ) = @_;

    my $req = $args_ref->{req} || Apache2::Request->new($r);
    my $reg = $r->pnotes( $r->user );

    my $ad_zone;
    if (my $id = $req->param('id')) {

      $ad_zone = $reg->get_ad_zone( $id );

    } elsif ($ad_zone_obj) {

      $ad_zone = $ad_zone_obj;

    }

    return Apache2::Const::NOT_FOUND unless $ad_zone;

    if ( $r->method_number == Apache2::Const::M_GET ) {

        my @ad_sizes = sort { $a->grouping <=> $b->grouping }
          sort { $a->name cmp $b->name } $reg->get_splash_sizes;

        my %tmpl_data = (
            ad_sizes => \@ad_sizes,
            ad_zone  => $ad_zone,
            errors   => $args_ref->{errors},
            req      => $req,
        );

        my $output;
        $Tmpl->process( 'ad/splash/edit.tmpl', \%tmpl_data, \$output, $r )
          || return $self->error( $r, $Tmpl->error );
        return $self->ok( $r, $output );
    }
    elsif ( $r->method_number == Apache2::Const::M_POST ) {

        # reset the method
        $r->method_number(Apache2::Const::M_GET);

        ##############################################################
        # validate input
        my @required = qw( name zone_type ad_size_id is_default active );
        my $constraints;
        if ( $req->param('zone_type') eq 'banner' ) {

            push @required, qw( image_href link_href );
            $constraints = {
                image_href => $self->valid_link(),
                link_href  => $self->valid_link(),
            };

        }
        elsif ( $req->param( 'zone_type' eq 'code' ) ) {

            push @required, 'code';
        }

        my %profile = ( required => \@required, );
        if ($constraints) {
            $profile{constraint_methods} = $constraints;
        }

        my $results = Data::FormValidator->check( $req, \%profile );

        if ( $results->has_missing or $results->has_invalid ) {
            my $errors = $self->SUPER::_results_to_errors($results);

            $r->log->debug( Dumper($errors) ) if DEBUG;

            return $self->dispatch_edit(
                $r,
                {
                    errors => $errors,
                    req    => $req
                }
            );
        }
        ############################################################

    }

    # remove this line and suffer the consequences
    my $code = $req->param('code');

    my %args = (
        reg_id     => $reg->reg_id,
        account_id => $reg->account->account_id,
        ad_size_id => $req->param('ad_size_id'),
        name       => $req->param('name'),
        active     => $req->param('active'),
        is_default => $req->param('is_default'),
    );

    $r->log->debug("splash args: " . Data::Dumper::Dumper(\%args)) if DEBUG;

    if ( $req->param('zone_type') eq 'code' ) {

        # use the invocation code
        $args{'code'}       = $req->param('code');
        $args{'image_href'} = '';
        $args{'link_href'}  = '';

    }
    elsif ( $req->param('zone_type') eq 'banner' ) {

        # create a simple link
        $args{'image_href'} = $req->param('image_href');
        $args{'link_href'}  = $req->param('link_href');
        $args{'code'}       = sprintf( '<a href="%s"><img src="%s"></a>',
            $args{'link_href'}, $args{'image_href'} );
    }


    # add arguments
    $ad_zone->$_( $args{$_} ) for keys %args;
    $ad_zone->update;
$r->log->error("ad sizes: " . Dumper($ad_zone));
    # done with argument processing
    $r->pnotes('session')->{msg} = sprintf( "Splash Page Ad '%s' was updated", $ad_zone->name);

    $r->headers_out->set(
        Location => $r->construct_url('/app/ad/splash/index') );
    return Apache2::Const::REDIRECT;
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

    my $output  = (defined $rand) ? $rand->code  : '';
    $r->content_type('text/javascript');
    return $class->ok($r, $output);
}



1;
