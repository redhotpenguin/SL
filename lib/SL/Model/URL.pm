package SL::Model::URL;

use strict;
use warnings;

use base 'SL::Model';
use Regexp::Assemble;

sub get_blacklisted_urls {
	my $class = shift;
	my $dbh = SL::Model->connect;
	my $sql = <<SQL;
SELECT url
FROM url
WHERE
blacklisted = 't'
SQL
	my $sth = $dbh->prepare($sql);
	$sth->execute;
	my @urls = map { $_->[0] } @{$sth->fetchall_arrayref};
	return wantarray ? @urls : \@urls;
}

sub blacklist_regex {
	my ($class) = @_;
	my @blacklists = $class->get_blacklisted_urls;
	my $blacklist_regex = Regexp::Assemble->new;
	$blacklist_regex->add(@blacklists);
	#print STDERR "Regex for blacklist_urls: ", $blacklist_regex->re, "\n\n";
	return $blacklist_regex;
}

1;