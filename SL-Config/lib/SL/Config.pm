package SL::Config;

use strict;
use warnings;

=head1 NAME

SL::Config

=head1 ABSTRACT

  use SL::Config;

  $cfg  = SL::Config->new( [ '/path/to/config/file.conf' ] );
  $val  = $cfg->key;
  @vals = $cfg->key;

=head1 DESCRIPTION

This package is responsible for handling Silver Lining configuration data.
It should make our lives less complex.
We don't care what it does under the hood, as long as the API works.

It tries to set Apache directives for as many variables as possible since they
are really fast.

=cut

our $VERSION = 0.16;

our( $config, $conf_dir );
our $file = 'sl.conf';

use base 'Config::ApacheFormat';
use FindBin;

sub new {
    my $class = shift;

    return $config if $config;

    my @config_files;
    # check the local conf dir first
    if ( -d "./conf" && ( -e "./conf/$file" ) )
    {

        $conf_dir = "./conf";
        @config_files = ( "$conf_dir/$file" );
 
    }
    elsif ( -d "$FindBin::Bin/../conf" && ( -e "$FindBin::Bin/../conf/$file" ) )
    {

        # development
        $conf_dir = "$FindBin::Bin/../conf";
        @config_files = ( "$conf_dir/$file", "$conf_dir/../$file" );
    # then  check for a global conf file
    } elsif ( -e "/etc/sl/$file" ) {

        # global sl dir
        $conf_dir     = "/etc/sl";
        @config_files = ("$conf_dir/$file");
    }
    elsif ( -e "/etc/$file" ) {

        # global etc
        $conf_dir     = "/etc";
        @config_files = ("$conf_dir/$file");
    }
   else {
        die "\nNo file $file found in  "
          . "$FindBin::Bin/../conf/ or /etc/sl/!\n";
    }

    # we have a configuration file to work with, so get to work
    $config = $class->SUPER::new();
    my $read;
    foreach my $config_file (@config_files) {
        next unless ( -e $config_file );
        $config->read($config_file);
        $read++;
    }
    die "\nNo config files read! conf_dir $conf_dir\n" unless $read;

    $config->autoload_support(1);
    return $config;
}

sub conf_dir {
    my $self = shift;
    return $conf_dir;
}

=item C<sl_db_params>

Returns an array reference

=cut

sub sl_db_params {
    my $self = shift;

}

sub tmpl_root {
    my $self = shift;
    return $self->sl_root . '/tmpl';
}

1;
__END__

# TODO - make directives work, possibly in a different module.

use Apache2::Const -compile => qw( TAKE1 RSRC_CONF OR_ALL );
use Apache2::Module   ();
use Apache2::CmdParms ();
use Apache2::Directive ();

use Apache2::ServerUtil;
use Apache2::ServerRec;

my @dirs = (
            {
             name         => 'SLRoot',
             errmsg       => 'the sl application root',
             args_how     => Apache2::Const::TAKE1,
             req_override => Apache2::Const::OR_ALL,
            }
           );

Apache2::Module::add(__PACKAGE__, \@dirs);

use Data::Dumper;
sub SLRoot {
    my ($cfg, $parms, $arg) = @_;
    print STDERR "\nSLRoot cfg " . Dumper($cfg) . ", parms $parms, arg $arg";
   $cfg->{_slroot} = $arg;
    print STDERR "\n222SLRoot cfg " . Dumper($cfg) . ", parms $parms, arg $arg";
}

sub SERVER_CREATE {
 my ($class, $parms) = @_;
    print STDERR  "\nSERVER_CREATE class $class, parms $parms";
    my $s = Apache2::ServerUtil->server;
    #my $cfg = $s->module_config;
    #print STDERR "\nMODULE CONFIG SERVER CREAETE IS " . Dumper($cfg);

    my $cfg = Apache2::Module::get_config(__PACKAGE__, $s);
    print STDERR "\nConfig is " . Dumper($cfg) . "\n";
    print STDERR "\nKeep alive is " . $s->keep_alive() . "\n";
    return bless {slroot => $cfg->{_slroot}, name => __PACKAGE__}, $class;
}

1;
