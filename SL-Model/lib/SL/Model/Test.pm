package SL::Model::Test;

use SL::Model;

my $default_sql_file;
my $db;
my $create;
my $build;
my $drop;

BEGIN {
    $default_sql_file = './sql/sl.sql';
    $db               = "sl_test_$$";
    $create           = `createdb $db`;
    $build            = `psql $db -f $default_sql_file `;
}

*SL::Model::connect = sub {
    my $class   = shift;
    my $params  = shift;
    my $connect = $class->connect_params;

    # override the database name
    $connect->[0] = $class->dsn( $db );

    my $dbh = DBI->connect_cached( @{$connect} );
    if ( !$dbh or ( $dbh && $dbh->err ) ) {
        print STDERR "Error connecting to database: "
          . $class->connect_params . ", "
          . $DBI::errstr . "\n";
        return;
    }
    return $dbh;
};

END {
    $drop = `dropdb $db`;
}

