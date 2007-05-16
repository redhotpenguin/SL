package SL::Model::Subrequest;

use strict;
use warnings;

use HTML::TokeParser ();
use URI ();

use SL::Model ();

=head1 NAME

SL::Model::Subrequest - sub-request detection and avoidance

=head1 SYNOPSIS

  my $subreq_tracker = SL::Model::Subrequest->new();

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

  $subreq_tracker->collect_subrequests(content_ref => \$content,
                                       base_url    => $url);

Finds all subrequests on a page and stores them in the DB.  Takes two
required named args: content_ref (reference to the page content) and
base_url (the URL of this page).  Returns the number of subreqs found.

=item is_subrequest

  $is_subreq = $subreq_tracker->is_subrequest(url => $url);

Checks a URL and returns true if the URL is a previously seen
sub-request.

=cut

sub new {
    my $pkg  = shift;
    my $self = bless {}, $pkg;
    return $self;
}

sub collect_subrequests {
    my ($self, %args) = @_;
    my ($content_ref, $base_url) = @args{qw(content_ref base_url)};

    my $parser = HTML::TokeParser->new( $content_ref );

    my $dbh = SL::Model->connect();
    my $sth = $dbh->prepare('INSERT INTO subrequest (url) VALUES (?)');

    # look for tags that can house sub-reqs
    my $count = 0;
    while ( my $token = $parser->get_tag('iframe', 'frame') ) {    
        my $attrs = $token->[1];
        my $url   = $attrs->{src};
        next unless $url;

        $count++;

        # get a normalized URL and skip if already known
        $url = _normalize_url($url, $base_url);
        next unless $url;
        next if $self->is_subrequest(url => $url);

        # send to the DB
        $sth->execute($url);
    }

    $sth->finish;
    # $dbh->commit; # currently autocommit

    return $count;
}

sub is_subrequest {
    my ($self, %args) = @_;
    my ($url) = @args{qw(url)};
    my $dbh   = SL::Model->connect();

    $url = _normalize_url($url);
    return 0 unless $url;

    # look for the URL
    my $sth = $dbh->prepare('SELECT 1 FROM subrequest WHERE url = ?');
    $sth->execute($url);
    my $exists = $sth->fetchrow_array() || 0;
    $sth->finish;

    return $exists;
}

# use URI to produce a single representation for equivalent URLs
sub _normalize_url {
    my ($url, $base_url) = @_;

	# special case - can't normalize 'about:blank'
	# given a base_url, this url normalizes, but otherwise it doesn't
	return "" if (($url eq 'about:blank') or ($url eq 'javascript:false;'));

    # canonicalize the URL
    my $canonical_url;
    if ($url =~ m!^https?://!) {
        # full url
        $canonical_url = URI->new($url)->canonical->as_string;
    } elsif ($url =~ m!^(w+):!) {
        # ignore fully-qualified non-http links
        return "";
    } elsif ($base_url) {
        # base the new URL on the base
        $canonical_url = URI->new_abs($url, URI->new($base_url))
          ->canonical->as_string;
    } else {
        warn "Unable to normalize $url!";
        return "";
    }

    return $canonical_url;
}


1;
