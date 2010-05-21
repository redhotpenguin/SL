package WebService::CityGrid

=head1 NAME

  WebService::CityGrid - Interface to the CityGrid web service API

=cut

use strict;
use warnings;

use Any::Moose;
use Any::URI::Escape;

has 'api_key'   => ( is => 'ro', isa => 'Str', required => 1 );
has 'publisher' => ( is => 'ro', isa => 'Str', required => 1 );

our $api_host = 'api2.citysearch.com';
our $api_base = "http://$api_host/search/";
our $VERSION  = '0.01';


1;


=head1 SYNOPSIS

  use WebService::CityGrid;
  $cs = WebService::CityGrid->new(
      api_key   => $my_apikey,
      publisher => $my_pubid, );

  $url = $cs->Search({ mode => 'locations', 
      where => '90210',
      what  => 'pizza%20and%20burgers', });

=head1 DESCRIPTION




=head1 SEE ALSO

L<http://developer.citysearch.com/docs/>

=head1 AUTHOR

Fred Moyer, E<lt>fred@slwifi.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2010 by Silver Lining Networks

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.12.0 or,
at your option, any later version of Perl 5 you may have available.


=cut

