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

    $self->format_adzone_list(\@ad_zones);

    my $link = 'https://app.silverliningnetworks.com/sl' . 
                '/splash/'
                  . Digest::MD5::md5_hex(
                    SALT + $r->pnotes( $r->user )->account->account_id);


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
            image_err => $args_ref->{image_err},
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
        my @required = qw( name zone_type is_default active );
        my $constraints;
        if ( $req->param('zone_type') eq 'banner' ) {

            push @required, qw( image_href link_href );
            $constraints = {
                image_href => $self->valid_splash_ad(),
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
                    image_err => $results->{image_err},
                    errors => $errors,
                    req    => $req
                }
            );
        }
        ############################################################

    }

    # remove this line and suffer the consequences
    my $code = $req->param('code');

    # calculate the weight
    my $weight = $self->display_weight( $req->param('display_rate') );


    my %args = (
        weight     => $weight,
        reg_id     => $reg->reg_id,
        account_id => $reg->account->account_id,
        name       => $req->param('name'),
        active     => $req->param('active'),
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
        String::Strip::StripLTSpace($args{'link_href'});
        String::Strip::StripLTSpace($args{'image_href'});

        $args{'code'}       = '';
#sprintf( '<a href="%s"><img src="%s"></a>',
 #           $args{'link_href'}, $args{'image_href'} );
    }



    ############################################
    # handle default
    my @default_zones = SL::Model::App->resultset('AdZone')->search({
	account_id => $reg->account_id,
                     ad_size_id => { -in => [ qw( 15 ) ] },
                    is_default => 1 });

    if ($req->param('is_default') == 1) {

      # null out the existing default zones
      foreach my $dz ( @default_zones ) {

        next if $dz->ad_zone_id == $ad_zone->ad_zone_id;

        $dz->is_default(0);
        $dz->update;
      }

      $ad_zone->is_default(1);

    } elsif (($req->param('is_default') == 0) or
	     (!$req->param('is_default'))) {

      # mark this one as default UNLESS there are no existing defaults

      if (@default_zones) {
        $ad_zone->is_default(0);

      } else {

        $ad_zone->is_default(1);
      }

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







# this serves the splash page

sub dispatch_splash {
    my ($class, $r) = @_;

    my $path = $r->path_info;
    $path = substr($path, 1, length($path)-1);

    my $ip = $r->connection->remote_ip;

    $r->log->debug("md5sum is " . $path) if DEBUG;
    $r->log->debug("remote ip: $ip") if DEBUG;

    my $slr_header = $r->headers_in->{'x-slr'};

    my @ad_zones;
    my $router;
    unless ($slr_header) {

      ($router) = SL::Model::App->resultset('Router')->search({
                           active => 1,
                           wan_ip => $ip, },
                           { order_by => 'last_ping DESC' }, );

      unless ($router) {

        $r->log->error("no device registered at ip $ip");
        return Apache2::Const::NOT_FOUND;
      }

      $r->log->debug("found router " . Dumper($router)) if DEBUG;

      # grab the medium rectangles
      @ad_zones = SL::Model::App->resultset('AdZone')->search({
	                 'me.ad_size_id' => 15,
                         'me.account_id' => $router->account_id,
			 'me.active'     => 1,
                         'router__ad_zones.router_id' => $router->router_id,},
                          { join =>'router__ad_zones' });


    } else {

      # get the specific device
      my ( $hash_mac, $router_mac ) = split( /\|/, $slr_header );

      # the leading zero is omitted on some sl_headers
      if ( length($hash_mac) == 7 ) {
            $hash_mac = '0' . $hash_mac;
      }

      die("Found invalid sl_header $slr_header")
          unless ( ( length($hash_mac) == 8 )
            && ( length($router_mac) == 12 ) );

      ($router) = SL::Model::App->resultset('Router')->search({
                          active => 't',
                          macaddr => $router_mac, });

      unless ($router) {
	  $r->log->error("no router found for header $slr_header");
	  return Apache2::Const::NOT_FOUND;
      }

      # grab the default medium rectangles
      @ad_zones = SL::Model::App->resultset('AdZone')->search({
                         'me.account_id' => $router->account_id,
			 'me.active'     => 1,
                         'router__ad_zones.router_id' => $router->router_id,},
                          { join =>'router__ad_zones' });

    }


    unless (@ad_zones) {
        # grab the default medium rectangles
        @ad_zones = SL::Model::App->resultset('AdZone')->search({
                         account_id => $router->account_id,
			 active => 1,
			 is_default => 't',
                         ad_size_id => 15, });


	if (@ad_zones == 0) {
	    $r->log->debug("no zones " . $r->connection->remote_ip) if DEBUG;
	    return Apache2::Const::NOT_FOUND;
	}
    }

    my $idx = int(rand(scalar(@ad_zones)));
    my $rand = $ad_zones[$idx];
    $r->log->debug("rand is $idx") if DEBUG;
    $r->log->debug(Dumper(\@ad_zones)) if DEBUG;

    my $output;
    if (defined $rand->code && ($rand->code ne '')) {

        $output = $rand->code;

      } elsif ((defined $rand->image_href && ($rand->image_href ne '')) &&
               (defined $rand->link_href && ($rand->link_href ne ''))) {

        my $image_href = $rand->image_href;
	if ($image_href =~ m{mesh\.com\/users\/\w+\/}) {

	    $r->log->debug("munging om image $image_href") if DEBUG;
	    $image_href =~ s/^(.*?\.com\/)(users\/[^\/]+)(\/.*)$/$3/;
	    $r->log->debug("munged image link $image_href") if DEBUG;
	}

        my $out_tmpl = <<TMPL;
var SL_%x = '';
SL_%x += "<"+"a href=\\'%s\\' target=\\'_blank\\'><"+"img src=\\'%s\\' width=\\'%d\\' height=\\'%d\\' alt=\\'%s\\' title=\\'%s\\' border=\\'0\\' /><"+"/a>\\n";
document.write(SL_%x);
TMPL
        my $id = int(rand(2**32));
        $output = sprintf($out_tmpl, $id, $id, $rand->link_href,
                          $image_href,
                          300, 250, $rand->name, $rand->name, $id);

      } else {
        $r->log->error("invalid splash zone " . $rand->ad_zone_id);
        return Apache2::Const::SERVER_ERROR;
      }

    $r->content_type('text/javascript');
    return $class->ok($r, $output);
}



1;
