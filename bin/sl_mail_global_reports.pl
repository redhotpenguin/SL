use strict;
use warnings;

use MIME::Lite;

my $FROM    = "SL Reporting Daemon <fred\@redhotpenguin.com>";
my $TO      = "fred\@redhotpenguin.com";
my $SUBJECT = "Global SL Report Graphs";
my $dir     = "/tmp/data/sl/global";

my $msg = MIME::Lite->new(
    From    => $FROM,
    To      => $TO,
    Subject => $SUBJECT,
    Type    => 'TEXT',
    Data    => "Reports for all routers attached"
);

foreach my $temporal qw( daily weekly monthly quarterly ) {
	foreach my $type qw( views clicks rates ads ) {
		$msg->attach(
			Type     => 'image/png',
			Path     => "$dir/$temporal/$type.png",
			Filename => "$temporal\_$type.png",
		) if (-e "$dir/$temporal/$type.png");
	}
}
$msg->send;

