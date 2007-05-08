package SL::Client::Config;

use strict;
use warnings;

use Apache2::Const -compile => qw( TAKE1 OR_ALL );
use Apache2::Module     ();
use Apache2::CmdParms   ();
use Apache2::Directive  ();
use Apache2::ServerUtil ();
use Apache2::ServerRec  ();

my @directives = ( {
                    name => 'SL_URL_Blacklist_File',
                    errmsg => 'URL Blacklist File Error',
                    args_how => Apache2::Const::TAKE1,
                    req_override => Apache2::Const::OR_ALL,
                    },
                   {
                    name => 'SL_UA_Blacklist_File',
                    errmsg => 'User Agent Blacklist File Error',
                    args_how => Apache2::Const::TAKE1,
                    req_override => Apache2::Const::OR_ALL,
                    },
                   {
                    name => 'SL_EXT_Blacklist_File',
                    errmsg => 'Extension Blacklist File Error',
                    args_how => Apache2::Const::TAKE1,
                    req_override => Apache2::Const::OR_ALL,
                    },
                   {
                    name => 'SL_Proxy_List_File',
                    errmsg => 'Proxy Service List File Error',
                    args_how => Apache2::Const::TAKE1,
                    req_override => Apache2::Const::OR_ALL,
                    },
                   {
                    name => 'SL_Open_Proxy_List_File',
                    errmsg => 'Open Proxy Service List File Error',
                    args_how => Apache2::Const::TAKE1,
                    req_override => Apache2::Const::OR_ALL,
                    },
);

Apache2::Module::add(__PACKAGE__, \@directives);

sub SERVER_CREATE {
  my $class = shift;
  return bless {}, $class;
}

sub SL_URL_Blacklist_File {
  set_val('SL_URL_Blacklist_File',  @_);
}

sub SL_UA_Blacklist_File {
  set_val('SL_UA_Blacklist_File',  @_);
}

sub SL_Proxy_List_File {
  set_val('SL_Proxy_List_File',  @_);
}

sub SL_Open_Proxy_List_File {
  set_val('SL_Open_Proxy_List_File', @_);
}

sub SL_EXT_Blacklist_File {
  set_val('SL_EXT_Blacklist_File', @_);
}

sub set_val {
	    my ($key, $self, $parms, $arg) = @_;
#        print STDERR "key $key, self $self, parms $parms, arg $arg\n";
        $self->{$key} = $arg;
        unless ($parms->path) {
	        my $srv_cfg = Apache2::Module::get_config($self, $parms->server);
            # set the value
            $srv_cfg->{$key} = $arg;
		}
}

1;
