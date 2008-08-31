#!perl

use strict;
use warnings;

my $perlbal_user = 'phred2';

unless ( _is_perlbal_running()) {
    # uh oh, houston we have a problem
    warn("$$ Uh oh, perlbal is not running.  Trying to start it...");

    my $start_perlbal = `/home/$perlbal_user/dev/perl/bin/perl /home/perlbal_user/dev/perl/bin/perlbal -d`;

    if ( my $running = _is_perlbal_running()) {
        warn("perlbal was started ok: $running");
	exit(0);
    } else {
    	warn("Perlbal could not be started, giving up.  ALERT ALERT!");
    }

}

sub _is_perlbal_running {

	my $is_perlbal_running = `ps aux  | grep 'perlbal -d' | grep -v 'grep'`;
	chomp($is_perlbal_running);

	return if ($is_perlbal_running eq '');

	return $is_perlbal_running;
}


