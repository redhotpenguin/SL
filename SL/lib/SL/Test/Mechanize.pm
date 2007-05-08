package SL::Test::Mechanize;

use strict;
use warnings;

use base 'WWW::Mechanize';

sub new {
    my %args = (
        cookie_jar   => {},
        max_redirect => 0,
        agent        =>
'Mozilla/5.0 (Macintosh; U; PPC Mac OS X Mach-O; en-US; rv:1.8.0.2) Gecko/20060308 Firefox/1.5.0.2'
    );
    my $mech = WWW::Mechanize->new(%args);
    $mech->delete_header('Connection');
    $mech->add_header('Connection' => 'keep-alive');
    $mech->delete_header('Keep-Alive');
    $mech->add_header('Keep-Alive' => '300');
    $mech->delete_header('Accept-Encoding');
    $mech->add_header('Accept-Encoding' => 'gzip,deflate');
    $mech->delete_header('Accept-Charset');
    $mech->add_header('Accept-Charset' => 'ISO-8859-1,utf-8;q=0.7,*;q=0.7');
    $mech->delete_header('Accept-Language');
    $mech->add_header('Accept-Language' => 'en-us;q=0.5');
    $mech->delete_header('Accept');
    $mech->add_header('Accept' =>
'text/xml,application/xml,application/xhtml+xml,text/html;q=0.9,text/plain;q=0.8,image/png,*/*;q=0.5'
    );
	return $mech;
}

1;