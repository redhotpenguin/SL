package SL::Apache::Proxy::PingHandler;

use strict;
use warnings;

use Apache2::Const -compile => qw( HTTP_SERVICE_UNAVAILABLE DONE SERVER_ERROR );
use Apache2::Log             ();
use Sys::Load                ();
use SL::Model                ();
use SL::Model::Proxy::Router ();

our $MAX_LOAD = 2;

sub handler {
    my $r = shift;

    my $minute_avg = [ Sys::Load::getload() ]->[0];
    my $dbh        = SL::Model->connect();
    unless ($dbh) {
        $r->log->error("Database is not responding: sysload $minute_avg");
        return Apache2::Const::HTTP_SERVICE_UNAVAILABLE;
    }

    # Register this router unless it is active
    unless (
        SL::Model::Proxy::Router->is_active(
            { ip => $r->connection->remote_ip }
        )
      )
    {

        # grab the mac address if there is one
        my ($macaddr) =
          $r->uri =~ m/\/(\w{2}\:\w{2}\:\w{2}\:\w{2}\:\w{2}\:\w{2})$/;

        my %args = ( ip => $r->connection->remote_ip );
        if ($macaddr) {
            $args{'macaddr'} = $macaddr;
        }
        my $ok = SL::Model::Proxy::Router->register( \%args );
        unless ($ok) {
            $r->log->error(
                "Error registering router at ip " . $r->connection->remote_ip );
            return Apache2::Const::SERVER_ERROR;
        }
    }

    return Apache2::Const::DONE if $minute_avg < $MAX_LOAD;
    $r->log->error("System max load $MAX_LOAD exceeded: $minute_avg");
    return Apache2::Const::HTTP_SERVICE_UNAVAILABLE;
}

1;
