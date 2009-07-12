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

                # create it
                $ad_zone =
                  SL::Model::App->resultset('AdZone')
                  ->create( { %args, reg_id => $reg->reg_id, code => '' } );

                $ad_zone->update;
            }

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
                $bug->update;
            }

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
              sprintf( "Twitter Zone Assigned to %d devices",
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
                  ->create( { %args, reg_id => $reg->reg_id, code => '' } );

                $ad_zone->update;
            }

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
                $bug->update;
            }

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
            my ($ad_zone) =
              SL::Model::App->resultset('AdZone')->search({
                ad_size_id => { -in => [ qw( 1 10 12  ) ] },
                account_id => $reg->account_id,
                active => 't',
            });

            my %bug_args = (
                ad_size_id => { -in => [ qw( 20 22 ) ]},
                account_id => $reg->account_id,
            );

            my ($bug) =
              SL::Model::App->resultset('AdZone')->search( \%bug_args );

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
              sprintf( "Banner Ads Assigned to %d devices",
                scalar(@routers) );

            $r->headers_out->set(
                Location => $r->headers_in->{'referer'});
            return Apache2::Const::REDIRECT;

          }
    }
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

    $r->log->debug("deleting ad zone $id") if DEBUG;

    $ad_zone->active(0);
    $ad_zone->update;

    $r->pnotes('session')->{msg} =
      sprintf( "Ad '%s' was deleted", $ad_zone->name );
    $r->headers_out->set( Location => $r->headers_in->{'referer'} );
    return Apache2::Const::REDIRECT;
}

1;
