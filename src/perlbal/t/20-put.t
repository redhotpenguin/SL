#!/usr/bin/perl

use strict;
use Perlbal::Test;

use Test::More 'no_plan';

my $port = new_port();
my $dir = tempdir();

my $conf = qq{
SERVER aio_mode = none

CREATE SERVICE test
SET test.role = web_server
SET test.listen = 127.0.0.1:$port
SET test.docroot = $dir
SET test.dirindexing = 0
SET test.enable_put = 1
SET test.enable_delete = 1
SET test.min_put_directory = 0
SET test.persist_client = 1
ENABLE test
};

my $msock = start_server($conf);

my $ua = ua();
ok($ua);

require HTTP::Request;

my $url = "http://127.0.0.1:$port/foo.txt";
my $disk_file = "$dir/foo.txt";
my $content;

sub put_file {
    my $req = HTTP::Request->new(PUT => $url);
    $content = "foo bar baz\n" x 1000;
    $req->content($content);
    my $res = $ua->request($req);
    return $res->is_success;
}

sub delete_file {
    my $req = HTTP::Request->new(DELETE => $url);
    my $res = $ua->request($req);
    return $res->is_success;
}

sub verify_put {
    ok(filecontent($disk_file) eq $content, "verified put");
}

# successful puts
foreach_aio {
    my $aio = shift;

    ok(put_file(), "$aio: good put");
    verify_put();
    unlink $disk_file;
};

# good delete
put_file();
ok(  -f $disk_file, "file exists");
ok(delete_file(), "delete file");
ok(! -f $disk_file, "file gone");
ok(! delete_file(), "deleting non-existent file");

# min_put_directory
ok(manage("SET test.min_put_directory = 2"), "min_put = 2");
foreach_aio {
    my $mode = shift;

    my $dir1 = "mode-$mode";
    my $path = "$dir1/dir2/foo.txt";
    $url = "http://127.0.0.1:$port/$path";
    $disk_file = "$dir/$path";
    ok(! put_file(), "aio $mode: bad put");
    ok(mkdir("$dir/$dir1"), "mkdir dir1");
    ok(mkdir("$dir/$dir1/dir2"), "mkdir dir1/dir2");
    ok(put_file(), "aio $mode: good put at dir1/dir2/foo.txt");
    verify_put();
    ok(unlink($disk_file), "rm file");
    ok(rmdir("$dir/$dir1/dir2"), "rm dir2");
    ok(rmdir("$dir/$dir1"), "rm dir1");
};

ok(manage("SET test.min_put_directory = 0"));

# let Perlbal autocreate a dir tree
foreach_aio {
    my $mode = shift;
    my $path = "tree-$mode/a/b/c/d/foo.txt";
    $url = "http://127.0.0.1:$port/$path";
    $disk_file = "$dir/$path";
    ok(put_file(), "$mode: made deep file");
    ok(-f $disk_file, "$mode: deep file exists");
};

# permissions
ok(put_file());
ok(manage("SET test.enable_put = 0"));
ok(! put_file(), "put disabled");
ok(manage("SET test.enable_delete = 0"));
ok(! delete_file(), "delete disabled");

1;
