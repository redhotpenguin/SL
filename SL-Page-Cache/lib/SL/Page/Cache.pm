package SL::Page::Cache;

use strict;
use warnings;

use MogileFS::Client ();
use SL::Config       ();

our $VERSION = 0.01;

my $CONFIG       = SL::Config->new;
my $MOGILE_HOST  = $CONFIG->sl_mogile_host || die 'no sl_mogile_host set';

sub new {
    my $class = shift;

    my $self = {};
    bless $self, $class;

    my $mogc = MogileFS::Client->new(
        domain => $class,
        hosts  => [$MOGILE_HOST],
    );

    $self->{mogc} = $mogc;
    return $self;
}

sub cache_url {
    my ( $self, $url ) = @_;

    my @cache_urls = $self->{mogc}->get_paths($url);

    return if (scalar(@cache_urls) == 0);

    return $cache_urls[0];
}

sub insert {
    my ( $self, $args_ref ) = @_;

    my $url = $args_ref->{url};
    unless ($url) { warn 'no url passed' && return }
    my $content_ref = $args_ref->{content_ref};
    unless ($content_ref) { warn 'no content_ref passed' && return }

    my $fh = $self->{mogc}->new_file( $url, __PACKAGE__ );

    print $fh $$content_ref;

    unless ( $fh->close ) {
        warn( "Error writing url $url: "
              . $self->{mogc}->errcode . ": "
              . $self->{mogc}->errstr );
        return;
    }

    my @urls = $self->{mogc}->get_paths($url);

    # return the first url only for now
    return $urls[0];
}

1;
