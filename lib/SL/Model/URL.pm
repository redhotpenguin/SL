package SL::Model::URL;

use strict;
use warnings;

use base 'SL::Model';
use Regexp::Assemble ();
use Digest::MD5 ();

my @URLS;
my $BLACKLIST_REGEX;

our $MAX_URL_ID;
our $url_query = <<SQL;
SELECT url
FROM url
WHERE
blacklisted = 't'
SQL

@URLS = __PACKAGE__->get_blacklisted_urls();

sub get_blacklisted_urls {
	my ($class) = @_;
    my $dbh = SL::Model->connect;
	my $sth = $dbh->prepare($url_query);
	$sth->execute;
    my @blacklisted_urls = map { $_->[0] }  @{$sth->fetchall_arrayref};
	return wantarray ? @blacklisted_urls : \@blacklisted_urls;
}

########
# this doesn't work if urls have been removed from the list - DEPRECATED
sub should_update_blacklist {
	my $class = shift;
	my $dbh = SL::Model->connect;
	my $sql = <<SQL;
SELECT max(url_id)
FROM url
WHERE blacklisted = 't'
SQL
	my $sth = $dbh->prepare($sql);
	$sth->execute;
	my $id_ref = $sth->fetchrow_arrayref;
	if ($MAX_URL_ID != $id_ref->[0]) {
		print STDERR "$$ Blacklist should be updated, id_ref is :" . $id_ref->[0] . "\n";
		$MAX_URL_ID = $id_ref->[0];
		return 1;
	}
	return;
}
#######

sub blacklist_regex {
	my ($class) = @_;

    # First check to see if the urls have changed.  We don't compare the count
    # because they can be added and subtracted, resulting in a net count of 0.
    my $dbh = SL::Model->connect;
	my $sth = $dbh->prepare($url_query);
	$sth->execute;
    my @recent_urls = $class->get_blacklisted_urls;

    # handle the first case where it's not defined
    if ($BLACKLIST_REGEX) {
        # compare the two arrays
        my $they_are_different = (
            Digest::MD5::md5_hex(join('', (sort { $a cmp $b } @URLS))) 
              ne
            Digest::MD5::md5_hex(join('', (sort { $a cmp $b } @recent_urls))) 
                              )
           ? 1 : 0;

        # if nothing has changed, return the existing regex
        unless ($they_are_different) {
            return $BLACKLIST_REGEX;
        }
    }

    # ok they have changed, log info level and recompute the regex
	$BLACKLIST_REGEX = Regexp::Assemble->new;
	$BLACKLIST_REGEX->add(@recent_urls);
	#print STDERR "$$ Regex for blacklist_urls computed: ", 
	#  $BLACKLIST_REGEX->re, "\n\n";

    # oh, don't forget to update the array
    @URLS = @recent_urls;
	return $BLACKLIST_REGEX;
}

1;
