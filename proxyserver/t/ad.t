#!perl

use strict;
use warnings FATAL => 'all';

use FindBin qw( $Bin );

use lib "$Bin/../lib";

use SL::Test;
use Test::More qw( no_plan );
use SL::Model::Ad;

my $pkg;

BEGIN {
    $pkg = 'SL::Model::Ad';
    use_ok($pkg);
}

my $method = "body_regex";
diag("Test the $method method");

my $content = _test_content( $method );
my $ad = _test_ad();

no strict 'refs';
my $sub = "SL::Model::Ad::$method";
my $page_with_ad = &$sub( $content, $ad );

ok( $page_with_ad =~ m/$ad/, "Ad content found in page");

$method = "container";
diag("Test the $method method");

$content = _test_content( $method );
$ad = _test_ad();

$sub = "SL::Model::Ad::$method";
my $css_url = "http://sl.redhotpenguin.com/container.css";
$page_with_ad = &$sub( $css_url, $content, $ad );

ok( $page_with_ad =~ m/$ad/, "Ad content found in page");

sub _test_ad {
    my $dir = "$Bin/data/ad";
    opendir(DIR, $dir) or die $!;
    my @files = grep { $_ !~ m/^\./ } readdir(DIR);
    closedir(DIR);
    
    my $file = int(rand(scalar(@files)));
    open(FH, "<$Bin/data/ad/" . $files[$file]) || die $!;
    return do { local $/; <FH> };
}

sub _test_content {
    my $method = shift;

    my $file = "$Bin/data/site/$method/index.html";
    open(FH, "<$file") or die $!;
    my $html = do { local $/; <FH> };
    close(FH);
    return $html;
}

