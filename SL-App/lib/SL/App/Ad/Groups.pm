package SL::App::Ad::Groups;

use strict;
use warnings;

use Apache2::Const -compile =>
  qw(OK SERVER_ERROR NOT_FOUND REDIRECT M_GET M_POST);
use Apache2::Log        ();
use Apache2::SubRequest ();
use Data::FormValidator ();
use Apache2::Request    ();
use Apache2::SubRequest ();
#use JavaScript::Minifier::XS qw(minify);

use base 'SL::App';

use SL::Model ();
use SL::Model::App ();
use SL::App::Template ();
use Data::Dumper;

our $TMPL = SL::App::Template->template();

use constant DEBUG => $ENV{SL_DEBUG} || 0;


sub dispatch_index {
    my ( $self, $r ) = @_;

    my $output;
    $TMPL->process( 'ad/groups/index.tmpl', {}, \$output, $r ) ||
      return $self->error( $r, $TMPL->error);

    return $self->ok( $r, $output );
}

sub dispatch_edit {
    my ( $self, $r, $args_ref ) = @_;

    my $req = $args_ref->{req} || Apache2::Request->new($r);
    my $reg = $r->pnotes( $r->user );

    my $ad_zone;

    if ( my $ad_zone_id = $req->param('id') ) {

        # edit existing ad zone
        $ad_zone = $reg->get_ad_zone($ad_zone_id);
        return Apache2::Const::NOT_FOUND unless $ad_zone;
    }

    my $ad_size_id;
    if ($ad_zone) {
        $ad_size_id = $req->param('ad_size_id')
          || $ad_zone->ad_size_id->ad_size_id;
    }
    else {
        $ad_size_id = $req->param('ad_size_id') || '';
    }

    if ( $r->method_number == Apache2::Const::M_GET ) {
        my %tmpl_data = (
            ad_sizes => [ sort { $a->grouping <=> $b->grouping }  sort { $a->name cmp $b->name } SL::Model::App->resultset('AdSize')->all ],
            ad_zone  => $ad_zone,
            errors   => $args_ref->{errors},
            req      => $req,
        );
        if ($ad_size_id) {
            $tmpl_data{ad_size_id} = $ad_size_id;
        }
        my @bug_lists;
        foreach my $ad_size ( SL::Model::App->resultset('AdSize')->all ) {
            my @bugs = SL::Model::App->resultset('Bug')->search(
                {
                    account_id => $reg->account_id->account_id,
                    ad_size_id => $ad_size->ad_size_id
                }
            );
            $tmpl_data{ 'bug_list_' . $ad_size->ad_size_id } = \@bugs;
            push @bug_lists, 'bug_list_' . $ad_size->ad_size_id;
        }
        $tmpl_data{bug_lists} = \@bug_lists;

        my $output;
        $TMPL->process( 'ad/groups/edit.tmpl', \%tmpl_data, \$output, $r ) ||
          return $self->error( $r, $TMPL->error);
        return $self->ok( $r, $output );
    }
    elsif ( $r->method_number == Apache2::Const::M_POST ) {

        # reset the method
        $r->method_number(Apache2::Const::M_GET);

        # validate input
        my %profile =
          ( required => [qw( name active ad_size_id code bug_id )], );

        my $results = Data::FormValidator->check( $req, \%profile );

        if ( $results->has_missing or $results->has_invalid ) {
            my $errors = $self->SUPER::_results_to_errors($results);

            return $self->dispatch_edit(
                $r,
                {
                    errors => $errors,
                    req    => $req
                }
            );
        }
    }

    my $code =
      $req->param('code');    # remove this line and suffer the consequences

	# fredify the invocation code for size
	#$code =~ s/(?:\t|\r|\n|\s{2,})/ /g;
	# $code = minify( $code );
	my %args = (
        reg_id     => $reg->reg_id,
        account_id => $reg->account_id->account_id,
        code       => $code,
        ad_size_id => $req->param('ad_size_id'),
        bug_id     => $req->param('bug_id'),
        name       => $req->param('name'),
        active     => $req->param('active'),
    );

    if ( my $double = $req->param('code_double') ) {
		#$double = minify( $double );
#		$double =~ s/(?:\t|\r|\n|\s{2,})/ /g;
        $args{'code_double'} = $double;
    }

    if ( !$req->param('id') ) {

        # create a new ad zone
        $ad_zone = SL::Model::App->resultset('AdZone')->create( \%args );
    }
    else {

        # add arguments
        $ad_zone->$_( $args{$_} ) for keys %args;
    }

    $ad_zone->update;

    # done with argument processing
    my $status = $req->param('id') ? 'updated' : 'created';
    $r->pnotes('session')->{msg} =
      sprintf( "Ad Zone '%s' was %s", $ad_zone->name, $status );

    $r->headers_out->set(
        Location => $r->construct_url('/app/ad/groups/list') );
    return Apache2::Const::REDIRECT;
}

sub dispatch_list {
    my ( $self, $r, $args_ref ) = @_;

    my $reg = $r->pnotes( $r->user );

    # get the ad zones this user has access to
    my @ad_zones = 
    		    sort { $b->{router_count} <=> $a->{router_count} } 
    		    sort { $b->mts cmp $a->mts }
    		    sort { $a->name cmp $b->name }  $reg->account_id->get_ad_zones;

    $r->log->debug( "ad zones: " . Dumper( \@ad_zones ) )
      if DEBUG;

    my %tmpl_data = (
        session  => $r->pnotes('session'),
        ad_zones => \@ad_zones,
        count    => scalar(@ad_zones),
    );

    my $output;
    $TMPL->process( 'ad/groups/list.tmpl', \%tmpl_data, \$output, $r ) ||
      return $self->error( $r, $TMPL->error);
    return $self->ok( $r, $output );
}

1;
