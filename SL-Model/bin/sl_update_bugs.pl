#!perl -w

use strict;
use warnings;

# get to work

use SL::Model::App;

my @accounts = SL::Model::App->resultset('Account')->all;

my @bugs = ( { ad_size_id => 1,
	image_href => 'http://www.silverliningnetworks.com/bugs/sl/leaderboard_sponsored_by.gif',
	link_href => 'http://www.silverliningnetworks.com/?referer=silverlining', },

	{ ad_size_id => 2,
	image_href => 'http://www.silverliningnetworks.com/bugs/sl/full_banner_sponsored_by.gif',
	link_href => 'http://www.silverliningnetworks.com/?referer=silverlining', },
	{
	ad_size_id => 3,
	image_href => 'http://www.silverliningnetworks.com/bugs/sl/text_ad_sponsored_by.gif',
	link_href => 'http://www.silverliningnetworks.com/?referer=silverlining', },

	{
	ad_size_id => 4,
	image_href => 'http://www.silverliningnetworks.com/bugs/sl/skyscraper_sponsored_by.gif',
	link_href => 'http://www.silverliningnetworks.com/?referer=silverlining', },

	{
	ad_size_id => 5,
	image_href => 'http://www.silverliningnetworks.com/bugs/sl/wide_skyscraper_sponsored_by.gif',
	link_href => 'http://www.silverliningnetworks.com/?referer=silverlining', },

	{
	ad_size_id => 6,
	image_href => 'http://www.silverliningnetworks.com/bugs/sl/half_page_ad_sponsored_by.gif',
	link_href => 'http://www.silverliningnetworks.com/?referer=silverlining', },
	{
	ad_size_id => 7,
	image_href => 'http://www.silverliningnetworks.com/bugs/sl/wide_skyscraper_sponsored_by.gif',
	link_href => 'http://www.silverliningnetworks.com/?referer=silverlining', },

    );

foreach my $account (@accounts) {
    foreach my $bug (@bugs) {
	$bug->{account_id} = $account->account_id;

	my $newbug = SL::Model::App->resultset('Bug')->find_or_create( $bug );
	$newbug->update;
    }
}


