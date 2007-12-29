package SL::Apache::App::Blacklist;

use strict;
use warnings;

use Apache2::Const -compile => qw(OK FORBIDDEN M_POST M_GET);
use Apache2::Log  ();
use Apache2::Request ();

use base 'SL::Apache::App';

use SL::App::Template ();
our $tmpl = SL::App::Template->template();

sub dispatch_index {
    my ($self, $r) = @_;

    my $req = Apache2::Request->new($r);
	my %tmpl_data;

    # serve the page
    @{ $tmpl_data{'urls'} } = sort { $b->ts cmp $a->ts }
      SL::Model::App->resultset('Url')->search( { blacklisted => 't' });

    if ($req->param('status')) {
      $tmpl_data{'status'} = $req->param('status');
      $tmpl_data{'url'} = $req->param('url');
    }

    if ($r->pnotes('root')) {
      $tmpl_data{'root'} = 1;
    }

    my $output;
    my $ok = $tmpl->process( 'blacklist.tmpl', \%tmpl_data, \$output, $r );
    $ok
      ? return $self->ok( $r, $output )
      : return $self->error( $r,
        "Template error: " . $tmpl->error() );
}

sub dispatch_delete {
    my ($self, $r) = @_;

    my $req = Apache2::Request->new($r);
    my $url_id = $req->param('url_id');

    $r->log->error("URL ID is $url_id");
    return Apache2::Const::SERVER_ERROR unless $url_id;
    my ($url) = SL::Model::App->resultset('Url')->search(
           { url_id => $url_id });
    return Apache2::Const::NOT_FOUND unless $url;

    # ok we have an url, take it off the blacklist;
    $url->blacklisted('f');
    $url->update;

    $r->method_number(Apache2::Const::M_GET);
    $r->internal_redirect("/app/blacklist/index?status=deleted&url_id=$url_id");
    return Apache2::Const::OK;
}

my %url_profile = ( required => [qw( url )], );

sub dispatch_edit {
    my ($self, $r, $errors ) = @_;

    my $req = Apache2::Request->new($r);
    my $url_id = $req->param('url_id');

    my ( %tmpl_data, $url, $output );
    if ( $url_id > 0 ) {   # edit existing url
        ($url) = SL::Model::App->resultset('Url')->search(
               { url_id => $url_id } );
        return Apache2::Const::NOT_FOUND unless $url;
        $tmpl_data{'url'} = $url;
    }
    elsif ( $url_id == -1 ) {
        $tmpl_data{'url'}{'url_id'} = $url_id;
    }

    if ($r->method_number == Apache2::Const::M_GET ) {
      
        if ( keys %{$errors} ) {
              $tmpl_data{'errors'} = $errors;
        }
  	    my $ok = $tmpl->process( 'blacklist/edit.tmpl', 
                                 \%tmpl_data, \$output, $r );
        $ok
          ? return $self->ok( $r, $output )
          : return $self->error( $r,
            "Template error: " . $tmpl->error() );
    }
    elsif ( $r->method_number == Apache2::Const::M_POST ) {

       my $results = Data::FormValidator->check( $req, \%url_profile );
       if ( $results->has_missing or $results->has_invalid ) {
            my %errors;
            if ($results->has_missing) {
                %{$errors{'missing'}} = map { $_ => 1 } $results->missing;
              }
            if ($results->has_invalid) {
                %{$errors{'invalid'}} = map { $_ => 1 } $results->invalid;
              }
            $r->method_number(Apache2::Const::M_GET);
            return $self->dispatch_edit($r, \%errors );
        }
        unless ($url) {
           # make sure monkeys aren't adding duplicate urls, bug 518
          my ($exists) = SL::Model::App->resultset('Url')->search({
              url => $req->param('url')});
          if ($exists) {
              $r->method_number(Apache2::Const::M_GET);
              $r->internal_redirect("/app/blacklist/index?status=exists&url=" .
                                    $req->param('url'));
              return Apache2::Const::OK;
           }
           $url   = SL::Model::App->resultset('Url')->new( {} );
        }
        $url->url( $req->param('url') );
        $url->reg_id($r->pnotes($r->user)->reg_id);

       my $status = 'updated';
       if ($url_id == -1) {
         $url->insert;
         $status = 'added';
       }
       $url->update;

       $r->method_number(Apache2::Const::M_GET);
       $r->internal_redirect("/app/blacklist/index?status=$status&url=" . 
                            $req->param('url'));
       return Apache2::Const::OK;
     }

}

1;
