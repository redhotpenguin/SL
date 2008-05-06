

use strict;
use warnings;

use LWP::UserAgent;
use Parallel::ForkManager;
use RHP::Timer;
use Data::Dumper;

my $usage = 'perl load.pl $MAX_PROCESSES $MAX_GETS';

my $MAX_PROCESSES = shift || die $usage;
my $MAX_PROC_GETS = shift || die $usage;

my @links=(
        'http://d.yimg.com/us.yimg.com/p/rids/20080505/i/r462507931.jpg?x=400&y=263&sig=FYABBcWUaCV_kvXT5TDE8A--',
        'http://img.fark.net/images/2007/site/farkLogo2.gif',
        'http://img0.fark.net/images/2002/links/new/ap.gif',
        'http://snopes.com/graphics/header/snopes_02.gif',
        'http://images.use.perl.org/topics/topicperl.gif',
        'http://www.tampabays10.com/',
        'http://gal.darkervision.com/',
        'http://www.wetherobots.com/',
        'http://www.ipdemocracy.com/',
        'http://www.kerneltrap.org/',
        'http://www.match.com/',
        'http://www.fitness-singles.com/',
        'http://www.blogger.com/',
        'http://www.pandora.com/',
        'http://www.leknott.com/',
        'http://www.crabcookermusic.com/',
        'http://www.johnsonlanddesign.com/',
        'http://www.sourceforge.net/',
        'http://www.spikesource.com/',
        'http://www.jambajuice.com/',
        'http://www.starbucks.com/',
        'http://www.peets.com/',
        'http://www.oracle.com/',
        'http://www.sleepycat.com/',
        'http://www.ucdavis.edu/',
        'http://www.snopes.com/',
        'http://www.itsmejulia.com/',
        'http://www.imdb.com/',
        'http://www.wikipedia.org/',
        'http://use.perl.org/',
        'http://www.perlmonks.org/',
        'http://www.sfgate.com/',
        'http://www.hvh.com/',
        'http://www.silverliningnetworks.com/',
        'http://horses.smugmug.com/',
        'http://www.redhotpenguin.com/',
        'http://www.fark.com/',
        'http://www.nytimes.com/',
        'http://www.perl.com/',
        'http://www.twitter.com/',
        'http://online.wsj.com/public/us',
        'http://www.drudgereport.com/',
        'http://www.techcrunch.com/',
        'http://www.valleywag.com/',
        'http://www.typepad.com/',
        'http://news.yahoo.com/',
        'http://www.youtube.com/',
        'http://www.slashdot.org/',
        'http://www.digg.com/',
        'http://www.reddit.com/',
        'http://www.latimes.com/',
        'http://search.cpan.org/',
        'http://www.myspace.com/',
        'http://www.facebook.com/',
        'http://www.violentacres.com/',
        'http://www.bitpusher.com/',
        'http://www.ibm.com/',
        'http://www.symantec.com/',
        'http://www.rightmedia.com/',
        'http://www.adbrite.com/',
        'http://www.adbrite.com/',
        'http://www.meebo.com/',
        'http://www.dfj.com/',
        'http://www.opuscapital.com/',
        'http://www.disneyland.com/',
        'http://www.sci.com/battlestar/',
        'http://www.huffingtonpost.com/',
        'http://www.democraticunderground.com/',
        'http://www.listverse.com/',
        'http://www.orionmagazine.org/',
        'http://www.bloomberg.com/',
        'http://www.deputy-dog.com/',
        'http://www.msnbc.com/',
        'http://www.msn.com/',
        'http://www.dailycamera.com/',
        'http://www.fresh99.com/',
        'http://www.washingtonpost.com/',
        'http://60minutes.yahoo.com/',
        'http://www.donklephant.com/',
        'http://www.jsmineset.com/',
        'http://www.labspaces.net/',
        'http://www.theseminal.com/',
        'http://blog.wired.com/',
);

my $pm = new Parallel::ForkManager($MAX_PROCESSES);
my $out_file = './out.txt';
open(FH, ">$out_file") or die $!;

my $global_timer = RHP::Timer->new;
$global_timer->start('global');

foreach my $proc_id (1..$MAX_PROCESSES) {

    $pm->start and next; # do the fork

    my $timer = RHP::Timer->new;
    my (%timer_data, $timer_name);

    my $ua = LWP::UserAgent->new;

    for my $get_id (1..$MAX_PROC_GETS) {
        my $link = _rand_link();

        $timer_name = "proc_id $proc_id, get_id $get_id, link $link";

        $timer->start($timer_name);

        _grab_link($ua, $link);

        $timer->stop;

        print FH sprintf("timer %s time %s\n",
                         $timer->current, $timer->last_interval);

    }

    $pm->finish; # do the exit in the child process
}
$pm->wait_all_children;

print FH "Concurrent connections:  $MAX_PROCESSES\n";
print FH "Requests per connection:  $MAX_PROC_GETS\n";
print FH "total time: " . $global_timer->stop . "\n";
print FH "avg req per second: " . 
    (($MAX_PROCESSES * $MAX_PROC_GETS ) / $global_timer->last_interval) . "\n";
close(FH);

sub _rand_link {
  return $links[int(rand(@links))];
}

sub _grab_link {
  my ($ua, $link) = @_;
  warn("grabbing link $link");
  my $res = $ua->get( $link, ':content_file' => '/dev/null' );
  warn("link $link got response " . $res->code);
  return 1;
}
