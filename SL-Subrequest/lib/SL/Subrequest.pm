package SL::Subrequest;

use strict;
use warnings;

our $VERSION = 0.07;

use String::Strip    ();
use HTML::TokeParser ();
use URI              ();

use SL::Cache ();
use base 'SL::Cache';

use SL::Static ();

use constant DEBUG => $ENV{SL_DEBUG} || 0;
use constant VERBOSE_DEBUG => $ENV{SL_VERBOSE_DEBUG} || 0;

=head1 NAME

SL::Subrequest - sub-request detection and avoidance

=head1 SYNOPSIS

  my $subreq_tracker = SL:Subrequest->new();

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

    if ( !$content_ref or (! defined $$content_ref) or ($$content_ref eq '') ) {
        warn("SL::Subrequest::collect_subrequests missing content_ref") if DEBUG;
        return;
    }

    my $parser = HTML::TokeParser->new($content_ref);
    $parser->attr_encoded(1);

    # look for tags that can house sub-reqs
    my ( @subrequests, %found, @ads );
    while (
        my $token = $parser->get_tag(
            qw(script iframe frame src script
              img link)
        )
      )
    {
        my $attrs = $token->[1];
        my $url;
        if ( $token->[0] eq 'link' ) {
            $url = $attrs->{href};

            # only handle static content links
            if ( defined $url ) {
                next
                  unless SL::Static->is_static_content(
                    { url => $url, type => $attrs->{type} } );
            }
        }
        else {    # everything else

            # is there a url for the src or is it inline?
            if ($attrs->{src}) {

              $url = $attrs->{src};

            } elsif ($token->[0] eq 'script') {

              # inline javascript, potential ad
              my $text = $parser->get_text;
              unless ($text) {

                # empty script tag?
                next;

              } else {

                # we got some script, check it out
                push @ads, \$text;
                next;
              }
            }
        }

        # skip these iframe and frame invalid targets
        next unless $url;

        # strip whitespace from the url (html::parser leaves it in)
        String::Strip::StripLTSpace($url);

        # get a normalized URL
        my $normalized_url = _normalize_url( $url, $base_url );
        next unless $normalized_url;

        # skip all ports that aren't 80
        next unless $normalized_url->port == 80;

        my $as_string = $normalized_url->canonical->as_string;

        # skip ones that we have found already
        next if exists $found{$as_string};
        $found{$as_string} = 1;

        # log for return
        push @subrequests, [ $url, $as_string, $token->[0], ];

        # skip if url already in the db
        next if $self->is_subrequest( url => $as_string );

        # put it in the cache
        $self->{cache}
          ->set( join( '|', 'subreq', $as_string ) => $token->[0] );
    }

    # ok now also grab any full urls embedded in <script> tags
    my @script_urls =
      $$content_ref =~
      m{<script[^>]+>.*?(http\:/\/\w+[^\/\'\"]+).*?<\/script>}sg;


    # get the unique urls
    my %unique;
    my @jses = map { [ $_ . '/', $_ . '/', '_script' ] }
      grep ( !$unique{$_}++, @script_urls );
#    $DB::single = 1;
    my @return_jses;
    foreach my $js (@jses) {

      my $normalized_url = _normalize_url( $js->[0], $base_url );
      next if $@;
      next unless $normalized_url->port == 80;
      push @return_jses, $js;
    }


    return { subreqs =>  \@subrequests, jslinks => \@return_jses,
             ads => \@ads };
}

sub replace_subrequests {
    my ( $self, $args_ref ) = @_;

    foreach my $param qw( port subreq_ref content_ref ) {
        unless ( exists $args_ref->{$param} ) {
            warn("replace_subrequests() called with empty param $param");
            return;
        }
    }

    my $port        = $args_ref->{'port'};
    my $content_ref = $args_ref->{'content_ref'};
    my $subreq_ref  = $args_ref->{'subreq_ref'};

    my $replaced = 0;
    foreach my $subrequest ( @{$subreq_ref} ) {

        # prepare the urls
        my $orig_url        = $subrequest->[0];
        my $replacement_url = URI->new( $subrequest->[1] );
        $replacement_url->port($port);
        $replacement_url = $replacement_url->canonical->as_string;

        print STDERR "=> orig url is $orig_url\n" if VERBOSE_DEBUG;
        print STDERR "==> new url $replacement_url\n\n" if VERBOSE_DEBUG;

        # run the substitution, match surrounding quotes to handle
        # mixed and absolute urls
        # change this regex and I will beat you with a stick
        # handle replacements inside javascript differently than
        # html tokens
        my $is_script = ( $subrequest->[2] eq '_script' ) ? 1 : 0;
        if ( !$is_script ) {
            my $matched =
              $$content_ref =~
              s/(\=\s?['"]?\s{0,3}?)\Q$orig_url\E/$1$replacement_url/sg;
            $replaced += $matched;

            if (VERBOSE_DEBUG) {
                warn("did not replace $orig_url with $replacement_url ok")
                  unless $matched;
                warn("replaced $matched urls for $replacement_url");
            }
        }
        elsif ($is_script) {
            my $is_script_replace =

              # thanks to dave_the_m on perlmonks for this gem
              $$content_ref =~ s{(<script[^>]+>.*?<\/script>)}{
                  my $s = $1;
                  $s =~ s{\Q$orig_url\E}{$replacement_url}gs;
                  $s;
                }sge;
            $replaced += $is_script_replace;
        }

    }

    return $replaced;
}

sub is_subrequest {
    my ( $self, %args ) = @_;
    my ($url) = @args{qw(url)};

    $url = _normalize_url($url);
    return 0 unless $url;

	# root domain, is not a subrequest
	return 0 if $url->path eq '/';

    # look for the URL
    my $exists = $self->{cache}->get( join( '|', 'subreq', $url ) );
    return $exists;
}

# use URI to produce a single representation for equivalent URLs
sub _normalize_url {
    my ( $url, $base_url ) = @_;

    # canonicalize the URL
    my $canonical_url;
    if ( $url =~ m!^http://! ) {    # we skip https on purpose thanks

        # full url
        $canonical_url = URI->new($url);
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

        if (substr($url,0,2) eq './') {

          $base_url = 'http://' . URI->new($base_url)->host;
        }

        # base the new URL on the base
        $canonical_url =
          URI->new_abs( $url, URI->new($base_url) );

    }
    else {
        warn "Unable to normalize $url!";
        return "";
    }

    return $canonical_url;
}

1;
