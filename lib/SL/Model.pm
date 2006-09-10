package SL::Model;

use strict;
use warnings;

use DBI;
use SL::Config;

our $cfg = SL::Config->new;

my $db_options = {
                  RaiseError         => 1,
                  PrintError         => 1,
                  AutoCommit         => 0,
                  FetchHashKeyName   => 'NAME_lc',
                  ShowErrorStatement => 1,
                  ChopBlanks         => 1,
			  };

sub connect_params {
    my $self = shift;

    my $db   = $cfg->sl_db_name;
    my $host = $cfg->sl_db_host;
    my $dsn  = "dbi:Pg:dbname='$db';host=$host";
    return [$dsn, $cfg->sl_db_user, $cfg->sl_db_pass, $db_options];
}

sub connect {
    my $class   = shift;
    my $connect = $class->connect_params;
    my $dbh     = DBI->connect_cached(@{$connect});
    if ($dbh->err or !$dbh) {
        print STDERR "Error connecting to database: "
          . $class->connect_params . ", "
          . $DBI::errstr . "\n";
        return;
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