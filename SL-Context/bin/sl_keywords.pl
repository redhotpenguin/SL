#!perl -w

use strict;
use warnings;

use SL::Context;

my $file = shift or die "no file passed\n";

open( FH, "<$file" ) or die $!;

my $content = do { local $/; <FH> };

my $keywords = SL::Context->collect_keywords( content_ref => \$content );

print "Keywords are:\n\n";

foreach
  my $key ( sort { $keywords->{$b} <=> $keywords->{$a} } keys %{$keywords} )
{
    print "$key => " . $keywords->{$key} . "\n";
}

