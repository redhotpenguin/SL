#!/usr/bin/perl -w
#===============================================================================
#
#         FILE:  insert.pl
#
#        USAGE:  ./insert.pl
#
#  DESCRIPTION:
#
#      OPTIONS:  ---
# REQUIREMENTS:  ---
#         BUGS:  ---
#        NOTES:  ---
#       AUTHOR:   (), <>
#      COMPANY:
#      VERSION:  1.0
#      CREATED:  04/24/06 23:19:37 PDT
#     REVISION:  ---
#===============================================================================

use strict;
use warnings;

use DBI;
use SL::CS::Model;

my $sql = <<SQL;
INSERT INTO reg
( ip, email, firstname, lastname, street_addr, apt_suite, zipcode, phone, description, macaddr, referer, serial_number, code  ) 
VALUES 
( ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ? )
SQL

my %params = (
	ip            => '10.0.0.3',
    email         => 'fred@redhotpenguin.com',
    firstname     => "Fred",
    lastname      => "Moyer",
    street_addr   => "1440 Union Street",
    apt_suite     => "302",
    zipcode       => "94109",
    phone         => '415.720.2103',
    description   => '',
    macaddr       => '0016B6288502',
    referer       => '',
    serial_number => "CL7A0F219620",
    code		=> "12345678",
  );	

my $dbh = SL::CS::Model->db_Main();
my $sth = $dbh->prepare($sql);
my $i   = 0;
$sth->bind_param( 1, $params{ip} );
$sth->bind_param( 2, $params{email} );
$sth->bind_param( 3, $params{firstname} );
$sth->bind_param( 4, $params{lastname} );
$sth->bind_param( 5, $params{street_addr} );
$sth->bind_param( 6, $params{apt_suite} );
$sth->bind_param( 7, $params{zipcode} );
$sth->bind_param( 8, $params{phone} );
$sth->bind_param( 9, $params{description} );
$sth->bind_param( 10, $params{macaddr} );
$sth->bind_param( 11, $params{referer} );
$sth->bind_param( 12, $params{serial_number} );
$sth->bind_param( 13, $params{code} );
my $rv = $sth->execute;
$dbh->commit;
if ($DBI::errstr) {
	print STDERR "Error: $DBI::errstr\n";
}

print "rv is $rv\n";
