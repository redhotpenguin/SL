package SL::Util;

use strict;
use warnings;

use HTML::TokeParser;
use URI;

sub not_html {
    my $content_type = shift;
    if ( $content_type !~ m/text\/html/ and $content_type !~ m/xml/ ) {
        return 1;
    }
}

sub collect_subrequest_links {
    my ($r, $content_ref, $base_url) = @_;

    my $parser = HTML::TokeParser->new( $content_ref );

    my $dbh = dbi_connect();
    my $sth = $dbh->prepare('INSERT INTO subrequest (url) VALUES (?)');

    # look for tags that can house sub-reqs
    while ( my $token = $parser->get_tag('iframe', 'frame', 'script') ) {    
        my $attrs = $token->[1];
        my $url   = $attrs->{src};
        next unless $url;

        # get a normalized URL and skip if already known
        $url = _normalize_url($url, $base_url);
        next if is_subrequest($r, $url, $dbh);

        # send to the DB
        $sth->execute($url);
    }

    $sth->finish;
    $dbh->commit;
}

sub is_subrequest {
    my ($r, $url, $dbh) = @_;
    $r->log->error("===> Checking URL $url");
    $url = _normalize_url($url);

    # connect unless a DBI handle was passed
    $dbh ||= dbi_connect();

    return 1
      if $dbh->selectrow_array('SELECT 1 FROM subrequest WHERE url = ?',
                               undef, $url);
    return 0;
}

# use URI to produce a single representation for equivalent URLs
sub _normalize_url {
    my ($url, $base_url) = @_;

    # canonicalize the URL
    my $canonical_url;
    if ($url =~ m!^http://!) {
        # full url
        $canonical_url = URI->new($url)->canonical->as_string;
    } elsif ($base_url) {
        # base the new URL on the base
        $canonical_url = URI->new_abs($url, URI->new($base_url))
          ->canonical->as_string;
    } else {
        die "Unable to normalize $url!";
    }

    return $canonical_url;
}

# copied this from SL::Apache::PerlAccessHandler - should probably
# make a shared module for this and put the creds in the conf file
sub dbi_connect {
    my ($db, $host, $user, $pass, $db_options, $dsn);
    $db   = 'sl';
    $host = 'localhost';
    $user = 'sam';
    $pass = '';
    $db_options = {RaiseError         => 1,
                   PrintError         => 1,
                   AutoCommit         => 0,
                   FetchHashKeyName   => 'NAME_lc',
                   ShowErrorStatement => 1,
                   ChopBlanks         => 1,};
    $dsn = "dbi:Pg:dbname='$db';host=$host";
    my $dbh = DBI->connect($dsn, $user, $pass, $db_options)
      or die $DBI::errstr;

    return $dbh;
}

1;
