package SL::Page::Cache;

use strict;
use warnings;

use MogileFS::Client ();
use Digest::MD5 ();
use SL::Config       ();

our $VERSION = 0.02;

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
    my ( $self, $args_ref ) = @_;

    my $url = $args_ref->{url} || die 'no url passed';

    my @cache_urls = $self->{mogc}->get_paths(Digest::MD5::md5_hex($url));

    return if (scalar(@cache_urls) == 0);

    return $cache_urls[0];
}

sub insert {
    my ( $self, $args_ref ) = @_;

    my $url = $args_ref->{url};
    unless ($url) { warn 'no url passed' && return }
    my $digest_url = Digest::MD5::md5_hex($url);

    my $content_ref = $args_ref->{content_ref};
    unless ($content_ref) { warn 'no content_ref passed' && return }

    my $bytes = $self->{mogc}->store_content( $digest_url, undef, $$content_ref );
    unless ($bytes) {
        die(sprintf("store_content: url %s, err: %s, content:%s ",$url, $self->{mogc}->errstr));
    }

    my @urls = $self->{mogc}->get_paths($digest_url);

    # return the first url only for now
    return $urls[0];
}

1;
