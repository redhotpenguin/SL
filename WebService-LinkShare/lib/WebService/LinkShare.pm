package WebService::LinkShare;

use strict;
use warnings;

our $VERSION = 0.01;

use URI::Escape    ();
use HTML::Entities ();
use XML::LibXML    ();
use LWP::UserAgent ();

our $Ua = LWP::UserAgent->new;
$Ua->agent(join(' ',__PACKAGE__, $VERSION));
$Ua->timeout(30);


=head1 NAME

WebService::LinkShare - Interface to the LinkShare web API

=head1 METHODS

=over 4

=item new()

 $Linkshare = WebService::LinkShare->new({ token => $token });

Get a token here:  L<http://cli.linksynergy.com/cli/publisher/links/webServices.php>

=cut


sub new {
    my ($class, $args) = @_;

    die "You need an api token to access the LinkShare API"
        unless (defined $args->{token});

    my %self; # old school OO

    $self{token} = $args->{token};

    bless \%self, $class;

    return \%self;
}


=item targeted_merchandise()

 $product_results = $Linkshare->targeted_merchandise({
     advertiser_mid => $mid,
     count          => 10, });

Returns an array ref of WebService::LinkShare::Product objects.

=cut

sub targeted_merchandise {
    my ($self, $args) = @_;

    die "need an advertiser mid" unless defined $args->{'advertiser_mid'};
    $args->{'count'} ||= 10;

    my $url = sprintf("http://feed.linksynergy.com/target?token=%s&mid=%d&count=%d",
        $self->{token},
        $args->{advertiser_mid},
        $args->{count});

    if ($args->{height} && $args->{width}) {

        $url .= '&height=' . $args->{height} . '&width=' . $args->{width};
    }

    if ($args->{url}) {
      $url .= URI::Escape::uri_escape(HTML::Entities::encode_numeric($args->{url}));
    }

    my $res = $Ua->get($url);

    die "request failed with status " . $res->status_line
      unless $res->is_success;

    my $dom = XML::LibXML->load_xml(
             string => $res->decoded_content, );

    my $root = $dom->documentElement;

    my $match_count = $root->getElementsByTagName('TotalMatches')->[0]->firstChild->getData;


    my %merch = ( count => $match_count );

    my @products;
    my @items = $root->getElementsByTagName('item');
    foreach my $item (@items) {

        my %product;

        foreach my $attr ( qw( productname clickurl adurl impressionurl ) ) {
           $product{$attr} = $item->getElementsByTagName($attr)->[0]->firstChild->getData;
        }

        my ($keywords) = $root->getElementsByTagName('keywords');
        if ($keywords->firstChild) {
          $product{keywords} = [ split(/\Q~~\E/, $keywords->firstChild->getData) ];
        }

        foreach my $attr ( qw( primary secondary ) ) {
          next unless $item->getElementsByTagName($attr)->[0]->firstChild;
          $product{category}{$attr} = $item->getElementsByTagName($attr)->[0]->firstChild->getData;
        }

        foreach my $attr( qw( short long ) ) {
          next unless $item->getElementsByTagName($attr)->[0]->firstChild;
          $product{description}{$attr} = $item->getElementsByTagName($attr)->[0]->firstChild->getData;
        }

        push @products, \%product;
    }

    $merch{products} = \@products;
    return \%merch;
}

1;

=head1 SYNOPSIS

  use WebService::LinkShare;
  $LinkShare = WebService::LinkShare->new({ token => $token });

  # figure out what advertiser id to pick for $mid
  $product_results = $LinkShare->targeted_merchandise({ advertiser_mid => $mid, count => 10 });

Use Data::Dumper to inspect the results data structure until I implement Moose :)

=head1 DESCRIPTION

See the LinkShare web services url to obtain a token for the
http://cli.linksynergy.com/cli/publisher/links/webServices.php

=head1 SEE ALSO

=over 4

=item Targeted Merchandiser API Implementation Guidelines PDF

L<http://helpcenter.linkshare.com/publisher/images/Targeted%20Merchandiser%20API.pdf>


=item Targeted Merchandiser API Implementation Guidelines HTML

L<http://helpcenter.linkshare.com/publisher/questions.php?questionid=653>

=back

=head1 AUTHOR

Fred Moyer, E<lt>fred@slwifi.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2010 by Silver Lining Networks

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.12.0 or,
at your option, any later version of Perl 5 you may have available.


=cut
