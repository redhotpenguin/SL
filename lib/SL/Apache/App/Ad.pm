package SL::Apache::App::Ad;

use strict;
use warnings;

use Apache2::Const -compile => qw(OK SERVER_ERROR NOT_FOUND M_GET M_POST);
use Apache2::Log        ();
use Apache2::SubRequest ();
use Data::FormValidator ();
use Apache2::Request    ();

use base 'SL::Apache::App';

# setup our template object
use SL::Config ();
my $config = SL::Config->new;

use Template ();
my %tmpl_config = ( INCLUDE_PATH => $config->tmpl_root . '/app' );
my $tmpl = Template->new( \%tmpl_config ) || die $Template::ERROR;

# this specific template logic
use Data::Dumper;
use SL::Model;
use SL::Model::App;    # works for now

use DateTime;

=head1 METHODS

=over 4

=item C<dispatch_index>

This method serves of the master ad control panel for now

=back

=cut

sub dispatch_list {
    my ( $self, $r ) = @_;
    my %tmpl_data;

    # grab the ads
	my $count = 0;
    if ( $r->pnotes('root') ) {

        # root user gets all ads
        @{ $tmpl_data{'ads'} } =
          sort { $a->ad_id <=> $b->ad_id } SL::Model::App->resultset('Ad')->all;
    }
    else {

        # thou art not root
        my @reg_ad_groups =
          SL::Model::App->resultset('RegAdGroup')
          ->search( { reg_id => $r->pnotes( $r->user )->reg_id } );
        my @ad_groups;
        foreach my $reg_ad_group (@reg_ad_groups) {
            push @ad_groups, $reg_ad_group->ad_group_id;
        }
        my @ads;
        foreach my $ad_group (@ad_groups) {
            push @ads, SL::Model::App->resultset('Ad')
              ->search( { ad_group_id => $ad_group->ad_group_id } );
        }
        @{ $tmpl_data{'ads'} } = sort { $a->ad_id <=> $b->ad_id } @ads;
    }
	$tmpl_data{'count'} = scalar(@{$tmpl_data{'ads'}});

    my $output;
    my $ok = $tmpl->process( 'ad/list.tmpl', \%tmpl_data, \$output );
    $ok
      ? return SL::Apache::App::ok( $r, $output )
      : return SL::Apache::App::error( $r,
        "Template error: " . $tmpl->error() );
}

my %ad_profile = ( required => [qw( link text ad_group_id active )], );

sub dispatch_report {
    my ( $self, $r ) = @_;

    my @DAYS = qw( 1 3 7 14 30 );

    # generate the results
    my $start = DateTime->now;
    my $end   = DateTime->now;
    my %results;
    foreach my $day (@DAYS) {
        my $end = DateTime->now->subtract( days => $day );
        $results{$day}{views}  = SL::CS::Model::Report->views( $end, $start );
        $results{$day}{clicks} = SL::CS::Model::Report->links( $end, $start );
    }

    my %tmpl_data;
    my $output;
    my $ok = $tmpl->process( 'ad/report.tmpl', \%tmpl_data, \$output );
}

sub dispatch_edit {
    my ( $self, $r ) = @_;

    my $req   = Apache2::Request->new($r);
    my $ad_id = $req->param('ad_id');

    my ( %tmpl_data, $ad, $output, $link );
    if ( $ad_id > 0 ) {    # edit existing ad
                           # grab the ad
        ($ad) = SL::Model::App->resultset('Ad')->search( { ad_id => $ad_id } );
        return Apache2::Const::NOT_FOUND unless $ad;
        $tmpl_data{'ad'} = $ad;
        ($link) =
          SL::Model::App->resultset('Link')->search( { ad_id => $ad_id } );
        $tmpl_data{'link'} = $link;
    }
    elsif ( $ad_id == -1 ) {
        $tmpl_data{'ad'}{'ad_id'} = $ad_id;
    }
    if ( $r->method_number == Apache2::Const::M_GET ) {

        # serve the form
		# AdGroups - FIXME - put in model class, $reg->ad_groups
		if ($r->pnotes('root')) {
			@{ $tmpl_data{'ad_groups'} } =
				SL::Model::App->resultset('AdGroup')->all;
		} else {
			my @reg_ad_groups = 
				SL::Model::App->resultset('RegAdGroup')->search({ 
					reg_id => $r->pnotes($r->user)->reg_id });
			@{ $tmpl_data{'ad_groups'} } = map { $_->ad_group_id } 
				@reg_ad_groups;
		}

  	    my $ok = $tmpl->process( 'ad/edit.tmpl', \%tmpl_data, \$output );
        $ok
          ? return SL::Apache::App::ok( $r, $output )
          : return SL::Apache::App::error( $r,
            "Template error: " . $tmpl->error() );
    }
    elsif ( $r->method_number == Apache2::Const::M_POST ) {
        my $req = Apache2::Request->new($r);
        my $results = Data::FormValidator->check( $req, \%ad_profile );
        if ( $results->has_missing or $results->has_invalid ) {
            %{ $tmpl_data{'missing'} } = map { $_ => 1 } $results->missing;
            %{ $tmpl_data{'invalid'} } = map { $_ => 1 } $results->invalid;
            my $ok = $tmpl->process( 'ad/edit.tmpl', \%tmpl_data, \$output );
        }
        unless ($ad) {
            $ad   = SL::Model::App->resultset('Ad')->new(   {} );
            $link = SL::Model::App->resultset('Link')->new( {} );
        }
        foreach my $attr qw( text active ad_group_id ) {
            $r->log->debug( "setting attr $attr to ", $req->param($attr) );
            $ad->$attr( $req->param($attr) );
        }
        $ad->template('text_ad');

        if ( $ad_id == -1 ) {
            $ad->insert;
        }
        $ad->update;

        if ( $ad_id == -1 ) {
            $link->ad_id( $ad->ad_id );
            $link->insert;
        }
        $link->uri( $req->param('link') );
        $link->active('t');
        $link->update;

        $r->internal_redirect('/app/ad/list');
        return Apache2::Const::OK;
    }
}

1;