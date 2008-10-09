package SL::Model::URL;

use strict;
use warnings;

use base 'SL::Model';
use Regexp::Assemble ();
use Digest::MD5      ();
use Cache::FastMmap  ();

our @URLS;
our $BLACKLIST_REGEX;
my $CACHE;

my $REGEX_DEBUG = 0;

our $URL_QUERY;
BEGIN {

    # setup the cache object;
    my $class = __PACKAGE__;
    $class =~ s/\:\:/_/g;

    $CACHE = Cache::FastMmap->new(
        share_file  => "/tmp/$class",
        raw_values  => 1,
        expire_time => 3600 * 24 * 30,    # 30 days
        cache_size  => '128m',
    );
    $URL_QUERY = <<SQL;
SELECT url
FROM url
WHERE
blacklisted = 't'
SQL

}

our $MAX_URL_ID;
@URLS = __PACKAGE__->get_blacklisted_urls();
$BLACKLIST_REGEX = __PACKAGE__->generate_blacklist_regex(\@URLS);

use Cache::Memcached ();
our $memd = Cache::Memcached->new({ servers => [ '127.0.0.1:11211' ] });


sub get_blacklisted_urls {
    my $class = shift;
    my $dbh     = SL::Model->connect;
    my $sth     = $dbh->prepare($URL_QUERY);
    $sth->execute;
    my @blacklisted_urls = map { $_->[0] } @{ $sth->fetchall_arrayref };
    return wantarray ? @blacklisted_urls : \@blacklisted_urls;
}

sub ping_blacklist_regex {
    my $class = shift;

    # First check to see if the urls have changed.  We don't compare the count
    # because they can be added and subtracted, resulting in a net count of 0.
    my @recent_urls = $class->get_blacklisted_urls;

    # handle the first case where it is defined
    if ($BLACKLIST_REGEX) {

        # compare the two arrays
        my $they_are_different = (
            Digest::MD5::md5_hex( join( '', ( sort { $a cmp $b } @URLS ) ) ) ne
              Digest::MD5::md5_hex(
                join( '', ( sort { $a cmp $b } @recent_urls ) )
              )
        ) ? 1 : 0;

        # if nothing has changed, return the existing regex
        return unless ($they_are_different);
    }

    $blacklist = $class->generate_blacklist_regex(\@recent_urls);
    $memd->set('blacklist_regex' => $blacklist );

    return $blacklist;
}

sub generate_blacklist_regex {
    my ($class, $urls_ref) = @_;

    unless ($urls_ref) {
        $urls_ref = $class->get_blacklisted_urls;
    }
    $BLACKLIST_REGEX = Regexp::Assemble->new->add(@{$urls_ref})->re;
    print STDERR sprintf("$$ Regex for blacklist_urls recomputed: %s\n", 
        $BLACKLIST_REGEX ) if $REGEX_DEBUG;
    
    # oh, don't forget to update the array
    @URLS = @{$urls_ref};
    return $BLACKLIST_REGEX;
}

sub not_html {
    my ( $self, %args ) = @_;
    my ($url) = @args{qw(url)};

    # check the cache to see if we know about this url
    my $content_type = $CACHE->get($url);

    if ( defined $content_type && ( $content_type !~ m/text\/html/ ) ) {
        return $content_type;
    }

    # we don't know about this url yet
    return;
}

1;
