package SL::Model::App::AdGroup;

use strict;
use warnings;

use base 'SL::Model::App';

sub get_ad_sls {
  my $self = shift;

  my @ad_ids = map { $_->ad_id } $self->ads;
  return unless (scalar(@ad_ids) > 0 );

  my @ad_sls = SL::Model::App->resultset('AdSl')->search({
           ad_id => { -in => \@ad_ids } });

  return unless (scalar(@ad_sls) > 0);

  return wantarray ? @ad_sls : \@ad_sls;

}

1;
