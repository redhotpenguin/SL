package SL::App::Ad::Twitter;

use strict;
use warnings;

use Apache2::Const -compile => qw(OK SERVER_ERROR NOT_FOUND M_GET M_POST);
use Apache2::Log        ();
use Apache2::SubRequest ();
use Apache2::Request    ();
use Apache2::SubRequest ();

use Data::FormValidator ();

use base 'SL::App';
use SL::App::Template ();
use SL::Model;
use SL::Model::App;    # works for now
use Data::Dumper;

use constant DEBUG => $ENV{SL_DEBUG} || 0;

our $Tmpl = SL::App::Template->template();

sub dispatch_index {
    my ( $self, $r, $args_ref ) = @_;

    my $req = $args_ref->{req} || Apache2::Request->new($r);
    my $reg = $r->pnotes( $r->user );

    my $twitter_id = $req->param('twitter_id');


    #####################################################
    # make sure we have a twitter ad zone
    my %args = (
        name       => '_twitter_feed',
        ad_size_id => 23,
        account_id => $reg->account_id,
        hidden     => 1,
    );

    my ($ad_zone) = SL::Model::App->resultset('AdZone')->search( \%args );
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

    my ($bug) = SL::Model::App->resultset('Bug')->search( \%bug_args );

    unless ($bug) {

        # create it
        $bug = SL::Model::App->resultset('Bug')->create(
            {
                %bug_args,
                image_href =>
                  'http://s1.slwifi.com/images/ads/sln/micro_bug.gif',
                link_href => 'http://www.silverliningnetworks.com/',
            }
        );
        $bug->update;
    }


    if ( $r->method_number == Apache2::Const::M_GET ) {

      my ($count) = $ad_zone->code =~ m/count\=(\d+)/s;

      my %tmpl_data = (
            count   => $count,
            ad_zone => $ad_zone,
            bug     => $bug,
            errors  => $args_ref->{errors},
            req     => $req,
        );

        my $output;
        $Tmpl->process( 'ad/twitter/index.tmpl', \%tmpl_data, \$output, $r )
          || return $self->error( $r, $Tmpl->error );
        return $self->ok( $r, $output );

    }
    elsif ( $r->method_number == Apache2::Const::M_POST ) {

        $r->method_number(Apache2::Const::M_GET);

        my %profile = (
            required           => [qw( twitter_id )],
            optional           => [qw( sweep )],
            constraint_methods => { twitter_id => $self->valid_twitter(), }
        );

        my $results = Data::FormValidator->check( $req, \%profile );

        if ( $results->has_missing or $results->has_invalid ) {
            my $errors = $self->SUPER::_results_to_errors($results);

            return $self->dispatch_index(
                $r,
                {
                    errors => $errors,
                    req    => $req
                }
            );
        }

        # twitter id is valid
        $reg->account->twitter_id( $req->param('twitter_id') );
        $reg->account->update;

        my $count = $req->param('count') || 1;
        my $code =
qq{<div id="twitter_div"><span id="twitter_update_list"></span></div><script type="text/javascript" src="http://s2.slwifi.com/js/blogger.js"></script><script type="text/javascript" src="http://twitter.com/statuses/user_timeline/$twitter_id.json?callback=twitterCallback2&count=$count"></script>};

        $ad_zone->code($code);
        $ad_zone->update;

        if ( !$req->param('sweep') ) {

            $r->pnotes('session')->{msg} =
"Twitter User Name updated to $twitter_id, $count random last tweets";

        }
        else {

            # sweep

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

            }

            $r->pnotes('session')->{msg} =
              sprintf(
                "Twitter User Name updated to %s, assigned to %d devices",
                $twitter_id, scalar(@routers) );
        }

        $r->headers_out->set( Location => $r->construct_url('/app/ad/index') );
        return Apache2::Const::REDIRECT;

    }
}

sub valid_twitter {
    my $self = shift;

    return sub {
        my $dfv = shift;
        my $val = $dfv->get_current_constraint_value;

        my $uri = eval { URI->new("http://twitter.com/$val") };
        if ($@) {
            warn("$$ problem creating URI object from twitter id $val: $@");
            return;
        }

        my $response = eval { $self->ua->get($uri) };
        if ($@) {
            warn( "problem grabbing uri " . $uri->as_string . ": $@" );
            return;
        }

        return $val if $response->is_success;
        return;    # oops didn't validate
      }
}

1;
