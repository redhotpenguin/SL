use strict;
use warnings;

use MIME::Lite;

my $FROM    = "SL Reporting Daemon <fred\@redhotpenguin.com>";
my $TO      = "info\@redhotpenguin.com";
my $SUBJECT = "Global SL Report Graphs";
my $dir     = "/tmp/data/sl/global/daily";

my $msg = MIME::Lite->new(
    From    => $FROM,
    To      => $TO,
    Subject => $SUBJECT,
    Type    => 'TEXT',
    Data    => "Reports for all routers attached"
);

foreach my $type qw( views clicks rates ads ) {
    $msg->attach(
        Type     => 'image/png',
        Path     => "$dir/$type.png",
        Filename => "$type.png",
    );
}

$msg->send;

