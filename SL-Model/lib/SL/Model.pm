package SL::Model;

use strict;
use warnings;

use DBI;
use SL::Config;

our $VERSION = 0.14;

use constant DEBUG => $ENV{SL_DEBUG} || 0;

my $db_options = {
                  RaiseError         => 0,
                  PrintError         => 1,
                  AutoCommit         => 1,
                  FetchHashKeyName   => 'NAME_lc',
                  ShowErrorStatement => 1,
                  ChopBlanks         => 1,
			  };

# DBI connect 
sub connect_params {
    my $self = shift;
    my $cfg = SL::Config->new;

 	return [ $self->dsn, $cfg->sl_db_user, $cfg->sl_db_pass, $db_options ];
}

# dsn
sub dsn {
	my $self = shift;
    my $cfg = SL::Config->new;
    my $db   = shift || $cfg->sl_db_name;
    my $dsn = "dbi:Pg:dbname='$db';";
	my $host = shift || $cfg->sl_db_host;
    unless (($host eq '127.0.0.1') or ($host eq 'localhost')) {
		# connection not over unix socket, specify connection host
		$dsn .= "host=$host;";
	}
	return $dsn;
}

sub connect {
    my $class   = shift;
	my $params = shift;
    my $connect = $class->connect_params;
	if (exists $params->{db}) {
        $connect->[0] = $class->dsn($params->{db});
	}

    my $dbh     = eval { DBI->connect_cached(@{$connect}) };
    if (!$dbh or ($dbh && $dbh->err) or $@) {
        warn(sprintf("Error %s connecting to database, %s, params %s",
             $@, $DBI::errstr, $class->connect_params));
        return;
    }
    return $dbh;
}

sub db_Main {
    __PACKAGE__->connect();
}

sub commit {
    my $self = shift;
    $self->connect->commit();
}

sub rollback {
    my $self = shift;
    $self->connect->rollback();
}

1;
