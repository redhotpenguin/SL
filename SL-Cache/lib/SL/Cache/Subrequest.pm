package SL::Cache::Subrequest;

use strict;
use warnings;

use String::Strip ();
use HTML::TokeParser ();
use URI              ();
use SL::Cache        ();
use base 'SL::Cache';

our $DEBUG = 0;

=head1 NAME

SL::Model::Subrequest - sub-request detection and avoidance

=head1 SYNOPSIS

  my $subreq_tracker = SL::Cache::Subrequest->new();

  # collect sub-requests from a page
  $subreq_tracker->collect_subrequests(content_ref => \$content,
                                       base_url    => $url,

  # determine if this URL is a sub-request
  $is_subreq = $subreq_tracker->is_subrequest(url => $url);

=head1 DESCRIPTION

This module is responsible for detecting and storing possible
sub-request, which should not have ads served.  This is done by
parsing the page and collecting src attributes.  The URLs are then
normalized and stored in the subrequest table.  Lookups are performed
on this table to find vet URLs before serving ads.

=head1 METHODS

=over 4

=item new

Create a new sub-request tracker.

=item collect_subrequests

  $subreq_ary_ref = $subreq_tracker->collect_subrequests(
                                       content_ref => \$content,
                                       base_url    => $url);

Finds all subrequests on a page and stores them in the cache.  Takes two
required named args: content_ref (reference to the page content) and
base_url (the URL of this page).  Returns an array reference of subrequests
found.

=item is_subrequest

  $is_subreq = $subreq_tracker->is_subrequest(url => $url);

Checks a URL and returns true if the URL is a previously seen
sub-request.

=cut

sub new {
    my $class = shift;
    my $self = $class->SUPER::new( type => 'raw' );
    return $self;
}

sub collect_subrequests {
    my ( $self,        %args )     = @_;
    my ( $content_ref, $base_url ) = @args{qw(content_ref base_url)};

    my $parser = HTML::TokeParser->new($content_ref);
    $parser->attr_encoded(1);

    # look for tags that can house sub-reqs
    my ( @subrequests, %found );
    while ( my $token = $parser->get_tag(qw(iframe frame src script img)) ) {
        my $attrs = $token->[1];
        my $url   = $attrs->{src};

        # skip these iframe and frame invalid targets
        next unless $url;

        # strip whitespace from the url (html::parser leaves it in)
        String::Strip::StripLTSpace($url);

        # get a normalized URL
        my $normalized_url = _normalize_url( $url, $base_url );
        next unless $normalized_url;

        # skip ones that we have found already
        next if exists $found{$normalized_url};
        $found{$normalized_url} = 1;

        # log for return
        push @subrequests, [ $url, $normalized_url, $token->[0], ];

        # skip if url already in the db
        next if $self->is_subrequest( url => $normalized_url );

        # put it in the cache
        $self->{cache}
          ->set( join ( '|', 'subreq', $normalized_url ) => $token->[0] );
    }
    return \@subrequests;
}

sub replace_subrequests {
    my ( $self, $args_ref ) = @_;

    foreach my $param qw( port subreq_ref content_ref ) {
        unless (exists $args_ref->{$param}) {
            warn("replace_subrequests() called with empty param $param");
            return;
        }
    }

    my $port        = $args_ref->{'port'};
    my $content_ref = $args_ref->{'content_ref'};
    my $subreq_ref  = $args_ref->{'subreq_ref'};

    foreach my $subrequest ( @{$subreq_ref} ) {

        # prepare the urls
        my $orig_url        = $subrequest->[0];
        my $replacement_url = URI->new( $subrequest->[1] );
        $replacement_url->port($port);
        $replacement_url = $replacement_url->canonical->as_string;
        print STDERR "=> orig url is $orig_url\n" if $DEBUG;
        print STDERR "==> replacement url is $replacement_url\n\n"
          if $DEBUG;

        # run the substitution, match surrounding quotes to handle
        # mixed and absolute urls
        # change this regex and I will beat you with a stick
        my $matched = $$content_ref =~
            s/((['"]|\=)\s{0,3}?)\Q$orig_url\E(['"]?)/$1$replacement_url$2/sg;
#           s/(['"\=]\s{0,3}?)\Q$orig_url\E(['"]?)/$1$replacement_url$2/sg;
        # match leading "

        warn("did not replace $orig_url with $replacement_url ok")
            unless $matched;
    }

    return 1;
}

sub is_subrequest {
    my ( $self, %args ) = @_;
    my ($url) = @args{qw(url)};

    $url = _normalize_url($url);
    return 0 unless $url;

    # look for the URL
    my $exists = $self->{cache}->get( join ( '|', 'subreq', $url ) );
    return $exists;
}

# use URI to produce a single representation for equivalent URLs
sub _normalize_url {
    my ( $url, $base_url ) = @_;

    # canonicalize the URL
    my $canonical_url;
    if ( $url =~ m!^https?://! ) {

        # full url
        $canonical_url = URI->new($url)->canonical->as_string;
    }
    elsif ( $url =~ m!^(\w+):! ) {

        # ignore fully-qualified non-http links such as ftp://..., irc://...,
        # file://...
        return "";
    }

    # skip these monkeys
    elsif (( $url eq 'about:blank' )
        or ( $url eq 'javascript:false;' ) )
    {
        return "";
    }
    elsif ($base_url) {

        # base the new URL on the base
        $canonical_url =
          URI->new_abs( $url, URI->new($base_url) )->canonical->as_string;
    }
    else {
        warn "Unable to normalize $url!";
        return "";
    }

    return $canonical_url;
}

1;
