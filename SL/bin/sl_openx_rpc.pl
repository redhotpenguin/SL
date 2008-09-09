#!perl -w

use strict;
use warnings;

use RPC::XML;
use RPC::XML::Client;

my $cli = RPC::XML::Client->new('http://127.0.0.1/openx/www/delivery/axmlrpc.php');

my $st = RPC::XML::struct->new('what' => 'zone:2');

my $ar = RPC::XML::array->new([ 0, 0 ]);

my $res = $cli->send_request('phpAds.view', $st, # what
                                            RPC::XML::string->new(''),   # campaignid
                                            RPC::XML::int->new(0),  # target
                                            RPC::XML::string->new(''),  # source
                                            RPC::XML::string->new(''),   # withtext
                                            RPC::XML::boolean->new(0),   # withtext
                                            $ar,  # context
                                        );

sleep 1;


