package SL::Util;

use strict;
use warnings;

use DBI;

sub not_html {
    my $content_type = shift;
    if ( $content_type !~ m/text\/html/ and $content_type !~ m/xml/ ) {
        return 1;
    }
}

# copied this from SL::Apache::PerlAccessHandler - should probably
# make a shared module for this and put the creds in the conf file.
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
    my $dbh = DBI->connect_cached($dsn, $user, $pass, $db_options)
      or die $DBI::errstr;

    return $dbh;
}

1;
