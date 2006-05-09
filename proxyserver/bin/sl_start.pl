#!/usr/bin/env perl

use strict;
use warnings;

use Template;
use FindBin;
use Perl6::Slurp;

my @config_data = ("$FindBin::Bin/../conf/sl.conf", "$FindBin::Bin/../sl.conf");
my %app_config;

foreach my $config_data_file (@config_data) {

	next unless -e $config_data_file;
    # Load the configuration data
    my $config_data = slurp $config_data_file;
    my @lines = split("\n", $config_data);
    foreach my $line (@lines) {
        chomp($line);
        $line =~ s/\s//g;
        my ($key, $value) = split('\|', $line);
        next unless ($key or $value);
        die if (($key && !$value) or (!$key && $value));
        $app_config{$key} = $value;
    }
}

# FIll out the httpd.conf
my $conf_tmpl   = "$FindBin::Bin/../conf/httpd.conf.tmpl";
my $tmpl_out    = "$FindBin::Bin/../conf/httpd.conf";
my %tmpl_config = (ABSOLUTE => 1, INCLUDE_PATH => "$FindBin::Bin/../conf/");
my $template    = Template->new(\%tmpl_config) || die $Template::ERROR, "\n";
$template->process($conf_tmpl, \%app_config, $tmpl_out)
  || die $template->error, "\n";

