package SL::CS::Model;

use strict;
use warnings;

use DBI;
use SL::Config;
my $cfg = SL::Config->new;

my $db = $cfg->sl_db_name;
my $host = $cfg->sl_db_host;
my $user = $cfg->sl_db_user;
my $pass = $cfg->sl_db_pass;
my $db_options = {
    RaiseError         => 1,
    PrintError         => 1,
    AutoCommit         => 0,
    FetchHashKeyName   => 'NAME_lc',
    ShowErrorStatement => 1,
    ChopBlanks         => 1,
};
my $dsn = "dbi:Pg:dbname='$db';host=$host";

sub connect {
    my $class = shift;
    my $dbh = DBI->connect_cached( $dsn, $user, $pass, $db_options );
    if ( $dbh->err ) {
        print STDERR "Error connecting to database:  dsn => $dsn, " .
            "user => $user, pass => $pass, errstr => " . $DBI::errstr . "\n";
    }
    return $dbh;
}

sub db_Main {
    __PACKAGE__->connect();
}

sub dbi_commit {
    my $self = shift;
    $self->connect->commit();
}

sub dbi_rollback {
    my $self = shift;
    $self->connect->rollback();
}

1;
