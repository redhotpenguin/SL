#!perl -w

use strict;
use warnings;
use English qw(no_match);

=head1 NAME

 [NAME]

=head1 SYNOPSIS

 [SYNOPSIS]

 myprog --opt1 --opt2

 myprog --help

 myprog --man
 
=cut

use Getopt::Long;
use Pod::Usage;

# Config options
my ($user, $pass);
my ($help, $man);

pod2usage(1) unless @ARGV;
GetOptions(
	'user=s' => \$user,
	'pass=s' => \$pass,
	'help'	   => \$help,
	'man'	   => \$man,
) or pod2usage(2);

pod2usage(1) if $help;
pod2usage( -verbose => 2) if $man;
pod2usage(1) unless $user && $pass;

# grab the latest ads
use SOAP::Lite;
my $SID = 1780200;
my $url = 
    "http://$user\:$pass\@apps.linksynergy.com/ws/services/TestPromotion?wsdl";
my $soap = SOAP::Lite->uri("TextPromotion")->proxy($url);
$|++;
print "Grabbing all links...\n";
my $result = $soap->GetAllLinks($SID);

if ($result->fault) {
   die "Oopsy: faultcode: " . $result->faultcode 
       . ", string: " . $result->faultstring . "\n";
}

# update the linkshare ads
use SL::Model::App;
print "Retrieving current links from database\n";
my (@current_linkshares) = SL::Model::App->resultset('AdLinkshare')->all;

# figure out which ads that we have aren't in the new resultset and deactivate
# them
my %new_ads = map { $_->{mid} . '_' . $_->{linkID} => 1 } @{$result->paramsall};
my @ads_to_deactivate = grep { not exists 
	$new_ads{$_->mid . '_' . $_->linkid}  } 
    @current_linkshares;

use DateTime;
use DateTime::Format::Pg;
my $ts = DateTime::Format::Pg->format_datetime(DateTime->now);
foreach my $ad_linkshare ( @ads_to_deactivate ) {
    $ad_linkshare->ad_id->active(0);
    $ad_linkshare->ad_id->update;

    $ad_linkshare->mts($ts);
	$ad_linkshare->update;
}

# do ads change? probably not, so just import the new ones
my %current_ads = map { $_->mid . '_' . $_->linkid => 1 } @current_linkshares;
my @new_ads = grep { not exists $current_ads{$_->{mid} . '_' . $_->{linkID}} } 
    @{$result->paramsall};
print "Adding new ads\n";
foreach my $ad ( @new_ads ) {
    my $new_ad = SL::Model::App->resultset('Ad')->new({ active => 't' });
    $new_ad->insert;
    $new_ad->update;

	my %args = map { lc($_) => $ad->{$_} } 
	    qw(mname mid linkID linkName linkUrl trackUrl category displayText);
    $args{ad_id} = $new_ad->ad_id;
    my $linkshare = SL::Model::App->resultset('AdLinkshare')->new(\%args);
    $linkshare->insert;
	$linkshare->update;
}
print "Done\n";
1;

__END__

=head1 DESCRIPTION

[DESCRIPTION]

=head1 OPTIONS

=over 4

=item B<opt1>

The first option

=item B<opt2>

The second option

=back

=head1 TODO

=over 4

=item *

Todo #1

=back

=head1 BUGS

None yet

=head1 AUTHOR

[AUTHOR]

=cut

#===============================================================================
#
#         FILE:  foo.pl
#
#        USAGE:  ./foo.pl 
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
#      CREATED:  12/21/06 00:24:23 PST
#     REVISION:  ---
#===============================================================================
