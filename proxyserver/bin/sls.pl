#!/usr/bin/env perl

use strict;
use warnings;

use FindBin;
use Template;
use Template::Context;
use Perl6::Slurp;

my @config_data =
  ( "$FindBin::Bin/../conf/sl.conf", "$FindBin::Bin/../sl.conf" );
my %app_config;

foreach my $config_data_file (@config_data) {

    next unless -e $config_data_file;

    # Load the configuration data
    my $config_data = slurp $config_data_file;
    my @lines = split( "\n", $config_data );
    foreach my $line (@lines) {
        next if $line =~ m{^#};
        chomp($line);
        $line =~ s/\s//g;
        my ( $key, $value ) = split( '\|', $line );
        next unless ( $key or $value );
        die "key: $key, value: $value\n"
          if ( ( $key && !$value ) or ( !$key && $value ) );
        $app_config{$key} = $value;
    }
}

# FIll out the httpd.conf
my $conf_tmpl   = "$FindBin::Bin/../conf/httpd.conf.tmpl";
my $tmpl_out    = "$FindBin::Bin/../conf/httpd.conf";
my %tmpl_config = ( ABSOLUTE => 1, INCLUDE_PATH => "$FindBin::Bin/../conf/" );
my $template    = Template->new( \%tmpl_config ) || die $Template::ERROR, "\n";
$template->process( $conf_tmpl, \%app_config, $tmpl_out )
  || die $template->error, "\n";

$|++;
my $cmd =
"$app_config{'sl_root'}/$app_config{'sl_version'}/$app_config{'sl_server'}/bin/httpd ";
$cmd .= "-X "
  if ( exists $app_config{'sl_debug'} && $app_config{'sl_debug'} == 1 );
$cmd .=
"-f $app_config{'sl_root'}/$app_config{'sl_version'}/$app_config{'sl_server'}/conf/httpd.conf -k start";
print "Starting with command: $cmd\n";
my $started = `$cmd`;
print $started;
