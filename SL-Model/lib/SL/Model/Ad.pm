package SL::Model::Ad;

use strict;
use warnings;

use base 'SL::Model';

use Template                           ();
use SL::Model::Proxy::Router::Location ();
use SL::Config                         ();

=head1 NAME

SL::Model::Ad

=head1 DESCRIPTION

This serves ads, ya see?

=cut

use constant AD_ZONE_ID          => 0;
use constant AD_ZONE_CODE        => 1;
use constant AD_ZONE_CODE_DOUBLE => 2;
use constant AD_SIZE_CSS_URL     => 3;
use constant AD_SIZE_JS_URL      => 4;
use constant AD_SIZE_HEAD_HTML   => 5;
use constant AD_SIZE_TEMPLATE    => 6;
use constant AD_SIZE_ID          => 7;
use constant BUG_IMAGE_HREF      => 8;
use constant BUG_LINK_HREF       => 9;
use constant PREMIUM             => 10;
use constant CLOSE_BOX           => 11;
use constant OUTPUT_REF          => 12;

use constant DEBUG => $ENV{SL_DEBUG} || 0;

our ( $CONFIG, $TEMPLATE );
our $Default_Ad_Data;

BEGIN {
    $CONFIG = SL::Config->new;

    require Data::Dumper if DEBUG;

    # create the default ad on startup and cache the data

    my $default_ad_zone_id = $CONFIG->default_ad_zone_id || 1;
    my $default_ad_sql = q{
SELECT

ad_zone.ad_zone_id,
ad_zone.code,
ad_zone.code_double,

ad_size.css_url,
ad_size.js_url,
ad_size.head_html,
ad_size.template,
ad_size.ad_size_id,

bug.image_href,
bug.link_href,

0, -- premium
1  -- close box

FROM ad_zone, bug, ad_size

WHERE ad_zone.ad_zone_id = ?
AND ad_zone.bug_id = bug.bug_id
AND ad_zone.ad_size_id = ad_size.ad_size_id
};

    my $dbh = SL::Model->connect() or die $DBI::errstr;
    my $sth = $dbh->prepare_cached($default_ad_sql);
    $sth->bind_param( 1, $default_ad_zone_id );
    my $rv = $sth->execute;
    die "Problem executing query: " . $default_ad_sql unless $rv;
    $Default_Ad_Data = $sth->fetchrow_arrayref;
    $sth->finish;
    die 'default ad does not exist!'
      unless defined $Default_Ad_Data->[AD_ZONE_ID];

    our $PATH = $CONFIG->sl_root . '/tmpl/';
    die "Template include path $PATH doesn't exist!\n" unless -d $PATH;

    our $TMPL_CONFIG = { ABSOLUTE => 1, INCLUDE_PATH => $PATH, };
    $TEMPLATE = Template->new($TMPL_CONFIG) || die $Template::ERROR, "\n";
}

=head1 METHODS

=over 4

=item C<container( $css_url, $response, $ad )>

Method for ad insertion which wraps the whole page in a stylesheet

=cut

our (
    $html_regex, $head_regex,     $start_body_regex,
    $uber_match, $end_body_match, $tail
);

BEGIN {
    $tail = qq{</div>};

    $head_regex = qr{^(.*?<\s*?head\s*?[^>]*?>)(.*)$}is;    # start of head
        #$head_regex          = qr{^(.*)(<\s*?\/head\s*?>.*)$}is;  # end of head
    $uber_match       = qr{\G(?:</\s*?head\s*?>)}i;
    $start_body_regex = qr{\G(.*?)<body([^>]*?)>(.*)$}is;
    $end_body_match   = qr{^(.*)(<\s*?/body\s*?>.*)$}is;
    $html_regex       = qr{^(.*?<\s*?html[^>]*?>)(.*)$}is;
}

our $DOCTYPE = <<DTDTYPE;
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd"><html xmlns="http://www.w3.org/1999/xhtml">
DTDTYPE

our $HEAD = <<HEAD;
<link rel="stylesheet" type="text/css" href="%s" /><script type="text/javascript" src="%s"></script>%s
HEAD

sub container {
    my ( $css_url_ref, $js_url_ref, $head_html_ref, $decoded_content_ref,
        $ad_ref, $ad_size_id )
      = @_;

    # check to make sure that we can insert all parts of the ad
    return
      unless ( ( $$decoded_content_ref =~ m/$head_regex/ )
        && ( $$decoded_content_ref =~ m/$start_body_regex/ ) );

    my $matched = $$decoded_content_ref =~ s{$html_regex}{$DOCTYPE$2};
    warn('failed to insert html content') unless $matched;

    # ignore failed tail matches
    #        && ( $$decoded_content_ref =~ m/$end_body_match/ ) );

    # build the head content
    my $head = sprintf( "$HEAD", $$css_url_ref, $$js_url_ref, $$head_html_ref );

    # Insert the head content
    $matched = $$decoded_content_ref =~ s{$head_regex}{$1$head$2};
    warn('failed to insert head content') unless $matched;

  # move the pointer to the end of the head tag - optimization, 0.5 milliseconds
    $$decoded_content_ref =~ m/$uber_match/;

    # Insert the rest of the pieces
    $matched = $$decoded_content_ref =~ s{$start_body_regex}
                         {$1<body$2>$$ad_ref$3};
    warn( 'failed to insert ad content ' . $$ad_ref ) unless $matched;

    # insert the tail
    $matched = $$decoded_content_ref =~ s{$end_body_match}{$1$tail$2};
    if (DEBUG) {
        warn('failed to insert closing div') unless $matched;
    }

    return 1;
}

=item C<body_regex> 

Method for ad insertion which puts an html paragraph right after the body tag.

  $page_with_ad = body_regex( $decoded_content, $ad );

=over 4

=item C<$decoded_content> ( string )

The decoded HTTP::Response content.

=item C<$ad> ( string )

The ad content

=back

=cut

sub body_regex {
    my ( $decoded_content, $ad ) = @_;
    $decoded_content =~ s{^(.*?)<body([^>]*?)>}{$1<body$2>$$ad}isxm;
    return $decoded_content;
}

=item C<_stacked_page($decoded_content, $ad)>

Method for ad insertion which puts the ad in the html page and serves that
inline with the original request response.

=cut

sub stacked {
    my ( $decoded_content, $ad ) = @_;
    my $html = qq{<html><body>$$ad</body></html>};
    $decoded_content = join( "\n", $html, $decoded_content );
    return $decoded_content;
}

use constant RANDOM_AD_ZONE_FROM_MAC => q{
SELECT

ad_zone.ad_zone_id,
ad_zone.code,
ad_zone.code_double,

ad_size.css_url,
ad_size.js_url,
ad_size.head_html,
ad_size.template,
ad_size.ad_size_id,

bug.image_href,
bug.link_href,

account.premium,
account.close_box

FROM ad_zone, bug, router, router__ad_zone, ad_size, account

WHERE router.macaddr = ?
AND router__ad_zone.router_id = router.router_id
AND router__ad_zone.ad_zone_id = ad_zone.ad_zone_id
AND ad_zone.bug_id = bug.bug_id
AND ad_zone.ad_size_id = ad_size.ad_size_id
AND ad_zone.account_id = account.account_id
ORDER BY RANDOM()
LIMIT 1
};

sub _random_ad_from_mac {
    my ( $class, $mac ) = @_;

    unless ($mac) {
        warn("no mac passed");
        return;
    }

    my $dbh = SL::Model->connect();
    my $sth = $dbh->prepare_cached(RANDOM_AD_ZONE_FROM_MAC);
    $sth->bind_param( 1, $mac );
    my $rv = $sth->execute;
    die "Problem executing query: " . RANDOM_AD_ZONE_FROM_MAC unless $rv;
    my $ad_data = $sth->fetchrow_arrayref;
    $sth->finish;

    unless ( defined $ad_data->[AD_ZONE_ID] ) {
        warn("No random ads returned for mac $mac") if DEBUG;
        return;
    }

    warn( "Random ad zone id found for mac $mac:" . $ad_data->[AD_ZONE_ID] )
      if DEBUG;
    return $ad_data;
}

# silverlining ad dispatcher
# this method returns a random ad, given the ip of the router

sub random {
    my ( $class, $args ) = @_;

    my $ip   = $args->{ip}   || warn("no ip passed")   && return;
    my $url  = $args->{url}  || warn("no url passed")  && return;
    my $mac  = $args->{mac}  || warn("no mac passed")  && return;
    my $user = $args->{user} || warn("no user passed") && return;
    my $premium = $args->{premium};

    # get the list of ad zones we can server for this router
    my $ad_data = $class->_random_ad_from_mac($mac) || $Default_Ad_Data;

    # process the template
    my $output_ref = $class->process_ad_template($ad_data);

    # return the id, string output ref, and css url
    return (
        $ad_data->[AD_ZONE_ID],         $output_ref,
        \$ad_data->[AD_SIZE_CSS_URL],   \$ad_data->[AD_SIZE_JS_URL],
        \$ad_data->[AD_SIZE_HEAD_HTML], $ad_data->[AD_SIZE_ID]
    );
}

# takes ad_data, returns scalar reference of output
sub process_ad_template {
    my ( $class, $ad_data ) = @_;

    unless ($ad_data) {
        require Carp
          && Carp::cluck("$$ no ad_data passed to process_ad_template");
        return;
    }

    my %tmpl_vars = (
        code           => $ad_data->[AD_ZONE_CODE],
        code_double    => $ad_data->[AD_ZONE_CODE_DOUBLE],
        bug_image_href => $ad_data->[BUG_IMAGE_HREF],
        bug_link_href  => $ad_data->[BUG_LINK_HREF],
        premium        => $ad_data->[PREMIUM],
        close_box      => $ad_data->[CLOSE_BOX],
    );

    warn( "tmpl vars: " . Data::Dumper::Dumper( \%tmpl_vars ) ) if DEBUG;

    # generate the ad
    my $output;
    $TEMPLATE->process( $ad_data->[AD_SIZE_TEMPLATE], \%tmpl_vars, \$output )
      || die $TEMPLATE->error();

    return \$output;
}

use constant LOG_VIEW_SQL => q{
-- LOG_VIEW_SQL
INSERT INTO view
( ad_zone_id, location_id, router_id, usr_id, url, referer, ip )
values
( ?,     (select location_id from location where ip = ?),
                      (select router_id from router where macaddr = ?),
                                 ?,
                                          ?,   ?,      ? )
};

sub log_view {
    my ( $class, $args_ref ) = @_;

    my $ip   = $args_ref->{ip}   || warn("no ip passed")   && return;
    my $url  = $args_ref->{url}  || warn("no url passed")  && return;
    my $mac  = $args_ref->{mac}  || warn("no mac passed")  && return;
    my $user = $args_ref->{user} || warn("no user passed") && return;
    my $ad_zone_id = $args_ref->{ad_zone_id}
      || warn("no ad_zone_id passed") && return;
    my $referer = $args_ref->{referer} || '';

    my $dbh = SL::Model->db_Main();
    my $sth = $dbh->prepare(LOG_VIEW_SQL);

    $sth->bind_param( 1, $ad_zone_id );
    $sth->bind_param( 2, $ip );
    $sth->bind_param( 3, $mac );
    $sth->bind_param( 4, $user );
    $sth->bind_param( 5, $url );
    $sth->bind_param( 6, $referer );
    $sth->bind_param( 7, $ip );

    my $rv;
    unless ( $rv = $sth->execute ) {
        warn(
            sprintf(
"$$ Error, could not log ad_zone_id %d, ip %s, url %s, router %s, user %s",
                $ad_zone_id, $ip, $url, $mac, $user
            )
        );
    }
    $sth->finish;
    return 1 if $rv;
    return;
}

1;
