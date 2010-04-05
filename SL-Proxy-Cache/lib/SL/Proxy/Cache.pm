package SL::Proxy::Cache;

use strict;
use warnings;

use SL::Config;
use Cache::Memcached ();

our $VERSION = 0.02;

our ($Config, $Memd);

BEGIN {
    $Config = SL::Config->new;
    $Memd = Cache::Memcached->new({ servers => [ '127.0.0.1:11211' ] });
}

sub new {
    my $class = shift;

    my %self = ( memd => $Memd );

    bless \%self, $class;

    return \%self;
}

sub memd {
  my $self = shift;
  return $self->{memd};
}

sub add_known_html {
    my ( $self, $url, $content_type ) = @_;
    unless ( $url && $content_type ) {
        warn("url $url or content type $content_type missing");
        return;
    }

    $self->memd->set( join ( '|', 'known_html', $url ) => $content_type );
    return 1;
}


sub is_known_html {
    my ( $self, $url ) = @_;
    die unless $url;

    my $content_type = $self->memd->get( join ( '|', 'known_html', $url ) );
    return 1 if ( $content_type && ( $content_type !~ m/text\/html/ ) );
    return;
}


sub add_known_not_html {
   my ( $self, $url, $content_type ) = @_;
    unless ( $url && $content_type ) {
        warn("url $url or content type $content_type missing");
        return;
    }

    $self->memd->set( join ( '|', 'known_not_html', $url ) => $content_type );
    return 1;
}

sub is_known_not_html {
    my ( $self, $url ) = @_;
    die unless $url;

    my $content_type = $self->memd->get( join ( '|', 'known_not_html', $url ));
    return $content_type;
}

1;
