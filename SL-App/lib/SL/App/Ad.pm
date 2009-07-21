package SL::App::Ad;

use strict;
use warnings;

use Apache2::Const -compile => qw(OK SERVER_ERROR NOT_FOUND M_GET M_POST);
use Apache2::Log        ();
use Apache2::SubRequest ();
use Data::FormValidator ();
use Apache2::Request    ();
use Apache2::SubRequest ();

use base 'SL::App';

use constant DEBUG => $ENV{SL_DEBUG} || 0;

use SL::App::Template ();
our $tmpl = SL::App::Template->template();

# this specific template logic
use Data::Dumper;
use SL::Model;
use SL::Model::App;    # works for now

sub dispatch_index {
    my ( $self, $r ) = @_;

    my $req = Apache2::Request->new($r);
    my $reg = $r->pnotes( $r->user );

    if ( $r->method_number == Apache2::Const::M_GET ) {

        my $output;
        $tmpl->process( 'ad/index.tmpl', {}, \$output, $r )
          || return $self->error( $r, $tmpl->error );
        return $self->ok( $r, $output );

    }
    elsif ( $r->method_number == Apache2::Const::M_POST ) {

        my $zone_type = $req->param('zone_type');


        unless ( $zone_type =~ m/(?:banner_ad|twitter|msg)/ ) {

          $r->log->error("invalid zone type $zone_type");
          return Apache2::Const::SERVER_ERROR
        }

        $r->log->debug("new zone type $zone_type") if DEBUG;

        $reg->account->zone_type($zone_type);
        $reg->account->update;

        if ( $zone_type eq 'twitter' ) {

            #####################################################
            # make sure we have a twitter ad zone
            my %args = (
                name       => '_twitter_feed',
                ad_size_id => 23,
                account_id => $reg->account_id,
                hidden     => 1,
            );

            my ($ad_zone) =
              SL::Model::App->resultset('AdZone')->search( \%args );

            unless ($ad_zone) {

		my $count = 5;
		my $twitter_id = $reg->account->twitter_id;
		my $code =
qq{<div id="twitter_div"><span id="twitter_update_list"></span></div><script type="text/javascript" src="http://s2.slwifi.com/js/blogger.js"></script><script type="text/javascript" src="http://twitter.com/statuses/user_timeline/$twitter_id.json?callback=twitterCallback2&count=$count"></script>};

                # create it
                $ad_zone =
                  SL::Model::App->resultset('AdZone')
                  ->create( { %args, reg_id => $reg->reg_id, code => $code } );
            }
            $ad_zone->is_default(1);
            $ad_zone->update;

            ######################################################
            # grab the branding image
            my %bug_args = (
                ad_size_id => 24,
                account_id => $reg->account_id,
            );

            my ($bug) =
              SL::Model::App->resultset('AdZone')->search( \%bug_args );

            unless ($bug) {

                # create it
                $bug = SL::Model::App->resultset('AdZone')->create(
                    {
			
			code => '',
			reg_id => $reg->reg_id,
			name => '_twitter_branding_image',
                        %bug_args,
                        image_href =>
                          'http://s1.slwifi.com/images/ads/sln/micro_bug.gif',
                        link_href => 'http://www.silverliningnetworks.com/',
                    }
                );
            }

            $bug->is_default(1);
            $bug->update;

            $self->no_defaults_except($ad_zone, $bug);

            my @routers =
              SL::Model::App->resultset('Router')
              ->search(
                { active => 't', account_id => $reg->account->account_id } );

            foreach my $router (@routers) {

                SL::Model::App->resultset('RouterAdZone')
                  ->search( { router_id => $router->router_id } )->delete_all;

                SL::Model::App->resultset('RouterAdZone')->find_or_create(
                    {
                        router_id  => $router->router_id,
                        ad_zone_id => $ad_zone->ad_zone_id,
                    }
                );

                SL::Model::App->resultset('RouterAdZone')->find_or_create(
                    {
                        router_id  => $router->router_id,
                        ad_zone_id => $bug->ad_zone_id,
                    }
                );

            }

            $r->pnotes('session')->{msg} =
              sprintf( "Twitter Zone assigned to %d devices",
                scalar(@routers) );

            $r->headers_out->set(
                Location => $r->headers_in->{'referer'} );
            return Apache2::Const::REDIRECT;

        }

        elsif ( $zone_type eq 'msg' ) {

            #####################################################
            # make sure we have a twitter ad zone
            my %args = (
                name       => '_message_bar',
                ad_size_id => 23,
                account_id => $reg->account_id,
                hidden     => 1,
            );

            my ($ad_zone) =
              SL::Model::App->resultset('AdZone')->search( \%args );

            unless ($ad_zone) {

                # create it
                $ad_zone =
                  SL::Model::App->resultset('AdZone')
                  ->create( { %args, reg_id => $reg->reg_id, code => 'This is the Silver Lining Networks default text message' } );
            }

            $ad_zone->is_default(1);
            $ad_zone->update;


            ######################################################
            # grab the branding image
            my %bug_args = (
                ad_size_id => 24,
                account_id => $reg->account_id,
            );

            my ($bug) =
              SL::Model::App->resultset('AdZone')->search( \%bug_args );

            unless ($bug) {

                # create it
                $bug = SL::Model::App->resultset('AdZone')->create(
                    {
                        %bug_args,
                        image_href =>
                          'http://s1.slwifi.com/images/ads/sln/micro_bug.gif',
                        link_href => 'http://www.silverliningnetworks.com/',
                    }
                );
            }
            $bug->is_default(1);
            $bug->update;

            $self->no_defaults_except($ad_zone, $bug);

            my @routers =
              SL::Model::App->resultset('Router')
              ->search(
                { active => 't', account_id => $reg->account->account_id } );

            foreach my $router (@routers) {

                SL::Model::App->resultset('RouterAdZone')
                  ->search( { router_id => $router->router_id } )->delete_all;

                SL::Model::App->resultset('RouterAdZone')->find_or_create(
                    {
                        router_id  => $router->router_id,
                        ad_zone_id => $ad_zone->ad_zone_id,
                    }
                );

                SL::Model::App->resultset('RouterAdZone')->find_or_create(
                    {
                        router_id  => $router->router_id,
                        ad_zone_id => $bug->ad_zone_id,
                    }
                );

            }

            $r->pnotes('session')->{msg} =
              sprintf( "Text Message assigned to %d devices",
                scalar(@routers) );

            $r->headers_out->set(
                Location => $r->headers_in->{'referer'} );
            return Apache2::Const::REDIRECT;


          } elsif ($zone_type eq 'banner_ad') {


            #####################################################
            # grab a random zone and assign it
            my ($ad_zone) =
              SL::Model::App->resultset('AdZone')->search({
                ad_size_id => { -in => [ qw( 1 10 12  ) ] },
                account_id => $reg->account_id,
                active => 't',
            });
            $ad_zone->is_default(1);
            $ad_zone->update;

            my %bug_args = (
                ad_size_id => { -in => [ qw( 20 22 ) ]},
                account_id => $reg->account_id,
            );

            my ($bug) =
              SL::Model::App->resultset('AdZone')->search( \%bug_args );

            $bug->is_default(1);
            $bug->update;

            $self->no_defaults_except($ad_zone, $bug);

            my @routers =
              SL::Model::App->resultset('Router')
              ->search(
                { active => 't', account_id => $reg->account->account_id } );

            foreach my $router (@routers) {

                SL::Model::App->resultset('RouterAdZone')
                  ->search( { router_id => $router->router_id } )->delete_all;

                SL::Model::App->resultset('RouterAdZone')->find_or_create(
                    {
                        router_id  => $router->router_id,
                        ad_zone_id => $ad_zone->ad_zone_id,
                    }
                );

                SL::Model::App->resultset('RouterAdZone')->find_or_create(
                    {
                        router_id  => $router->router_id,
                        ad_zone_id => $bug->ad_zone_id,
                    }
                );

            }


            $r->pnotes('session')->{msg} =
              sprintf( "Banner Ads assigned to %d devices",
                scalar(@routers) );

            $r->headers_out->set(
                Location => $r->headers_in->{'referer'});
            return Apache2::Const::REDIRECT;

          }
    }
}

sub no_defaults_except {
    my ($class, $ad_zone, $bug ) = @_;

    # handle defaults
    my @default_zones =
    SL::Model::App->resultset('AdZone')->search( { is_default => 1,
						 account_id => $ad_zone->account_id} );

    # null out the existing default zones
    foreach my $dz (@default_zones) {

        next if $dz->ad_zone_id == $ad_zone->ad_zone_id;
        next if $dz->ad_zone_id == $bug->ad_zone_id;
        $dz->is_default(0);
        $dz->update;
    }

    return 1;
}

sub dispatch_deactivate {
    my ( $class, $r, $args_ref ) = @_;

    my $reg = $r->pnotes( $r->user );
    my $req = Apache2::Request->new($r);

    my $id = $req->param('id');

    my ($ad_zone) = SL::Model::App->resultset('AdZone')->search(
        {
            account_id => $reg->account_id,
            ad_zone_id => $id,
            active     => 't',
        }
    );

    return Apache2::Const::NOT_FOUND unless $ad_zone;

    my $is_default = $ad_zone->is_default;

    $r->log->debug("deleting ad zone $id") if DEBUG;
    $ad_zone->is_default(0);
    $ad_zone->active(0);
    $ad_zone->update;
    

    # if this ad zone is default replace it with a new default
    if ($is_default == 1)  {

	my @ad_sizes;
	if ($ad_zone->ad_size_id =~ m/(?:1|10|12)/) {

	    @ad_sizes = qw( 1 10 12 );

	} elsif ($ad_zone->ad_size_id =~ m/(?:20|22)/) {

	    @ad_sizes = qw( 20 22 );

	} elsif ($ad_zone->ad_size_id == 15) {

	    @ad_sizes = qw( 15 );
	    
	}

	    my @others =  SL::Model::App->resultset('AdZone')->search({
		account_id => $ad_zone->account_id,
		ad_size_id => { -in => [ @ad_sizes ] },
		active => 't',
		is_default => 0 });
		
	    if (@others > 0) {
		my $rand = $others[int(rand(scalar(@others)-1))];
		$rand->is_default(1);
		$rand->update;
	    }
    }


    $r->pnotes('session')->{msg} =
      sprintf( "Ad '%s' was deleted", $ad_zone->name );
    $r->headers_out->set( Location => $r->headers_in->{'referer'} );
    return Apache2::Const::REDIRECT;
}

1;
