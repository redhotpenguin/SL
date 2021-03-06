package SL::Static;

use strict;
use warnings;

use Regexp::Assemble;
use SL::Config;

our $VERSION = 0.14;

use constant DEBUG => $ENV{SL_DEBUG} || 0;
our ($CONFIG, $EXT_REGEX);

BEGIN {
    $CONFIG = SL::Config->new();
    my @extensions = qw(
		ad ads avi aac
		bin bz2 bzip class css dll dms doc exe fla flv flac
		gif gz ico img iso jar jpg jpeg js
		lha lzh mar mkv mov mp3 mpg mpeg
		ogg pdf pls png ppt psf
		rar rdf rss sit shn so swf
		tar tgz tif tiff torrent txt
		wav wmv vob xls xpi zip );


	$EXT_REGEX = Regexp::Assemble->new->add(@extensions)->re;
    print STDERR "Extensions regex for SL::Static is $EXT_REGEX\n" if DEBUG;
}

sub is_static_content {
    my ($class, $args_ref) = @_;

    unless (exists $args_ref->{url}) {
        warn("is_static_content called without url");
        return;
    }

    if ($args_ref->{type}) {
        # check the type first, everything is static except html
        return 1 if ($args_ref->{type} ne 'text/html');
    }

    # match static ext followed by args ? or by nothing
    return 1 if ( ( $args_ref->{url} =~ m{\.(?:$EXT_REGEX)\Q?\E}i )
               or ( $args_ref->{url} =~ m{\.(?:$EXT_REGEX)$}i ) );

    return;
}

1;
