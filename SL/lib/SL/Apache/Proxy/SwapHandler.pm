package SL::Apache::Proxy::SwapHandler;

use strict;
use warnings;

=head1 NAME

SL::Apache::SwapHandler

=head1 DESCRIPTION

Swaps out ads.

=head1 DEPENDENCIES

Mostly Apache2 and HTTP class based.

=cut

# mp core
use Apache2::Const -compile => qw( OK SERVER_ERROR NOT_FOUND DECLINED
  REDIRECT LOG_DEBUG LOG_ERR LOG_INFO CONN_KEEPALIVE HTTP_BAD_REQUEST
  HTTP_UNAUTHORIZED HTTP_SEE_OTHER HTTP_MOVED_PERMANENTLY DONE
  HTTP_NO_CONTENT HTTP_PARTIAL_CONTENT HTTP_NOT_MODIFIED );
use Apache2::Connection  ();
use Apache2::Log         ();
use Apache2::RequestRec  ();
use Apache2::RequestUtil ();
use Apache2::RequestIO   ();
use Apache2::Response    ();
use Apache2::ServerRec   ();
use Apache2::ServerUtil  ();
use Apache2::URI         ();
use Apache2::Filter      ();
use APR::Table           ();

# sl libraries
use SL::Config               ();
use SL::HTTP::Client         ();
use SL::Model::Proxy::Ad     ();

use SL::Model::Proxy::Router ();
use SL::Apache::Proxy        ();

# non core perl libs
use Compress::Zlib   ();
use URI::Escape      ();

our $Config;

BEGIN {
    $Config = SL::Config->new;
}

use constant DEBUG         => $ENV{SL_DEBUG}            || 0;
use constant VERBOSE_DEBUG => $ENV{SL_VERBOSE_DEBUG}    || 0;


require Data::Dumper if ( DEBUG or VERBOSE_DEBUG );

sub handler {

    my $r = shift;

    return SL::Apache::Proxy->handler(__PACKAGE__, $r);
}



}

1;
