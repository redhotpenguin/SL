package SL::Static;

use strict;
use warnings;

use Regexp::Assemble;
use SL::Config;

our $VERSION = 0.10;

our $DEBUG = 0;
our ($CONFIG, $EXT_REGEX, $SKIPS_REGEX);

BEGIN {
    $CONFIG = SL::Config->new();
    # TODO - need to parse javascript files
    my @extensions = qw( ad avi bin bz2 css doc exe fla gif gz ico jpeg 
        jpg js mar pdf png ppt rar rdf sit rss tgz txt wmv vob xpi zip );
    $EXT_REGEX = Regexp::Assemble->new->add(@extensions)->re;
    print STDERR "Extensions regex for SL::Static is $EXT_REGEX\n" if $DEBUG;

    my @skips = qw( framset adwords.google.com MM_executeFlashDetection
                 swfobject.js );
    push @skips, 'Ads by Goooooogle';
    $SKIPS_REGEX = Regexp::Assemble->new->add(@skips)->re;
    print STDERR "Skips regex for SL::Static is $SKIPS_REGEX\n" if $DEBUG;
}

sub is_static_content {
    my $args_ref = shift;
    unless ((exists $args_ref->{url}) or (exists $args_ref->{type})) {
        warn(sprintf("is_static_content called without args, url %s, type %s",
                    $args_ref->{url}, $args_ref->{type}));
        return;
    }

    if ($args_ref->{type}) {
        # check the type first, everything is static except html
        return 1 if ($args_ref->{type} ne 'text/html');
    }

    if ($args_ref->{url}) {
      return 1 if ( $args_ref->{url} =~ m{\.(?:$EXT_REGEX)$}i );
    }

    return;
}

sub contains_skips {
    my $content_ref = shift;
    die unless $content_ref;

    return 1 if ($$content_ref =~ m/$SKIPS_REGEX/is);
    return;
}

1;
