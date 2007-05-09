package SL::Config;

use strict;
use warnings;

=head1 NAME

SL::Config

=head1 ABSTRACT

  use SL::Config;

  $cfg  = SL::Config->new()
  $val  = $cfg->key
  @vals = $cfg->key

=head1 DESCRIPTION

This package is responsible for handling Silver Lining configuration data.
It should make our lives less complex.
We don't care what it does under the hood, as long as the API works.

It tries to set Apache directives for as many variables as possible since they
are really fast.

=cut

# setup the application root to determine where the conf file is.
# assume that the app is layed out $sl_root/conf $sl_root/bin
our ( $sl_root, $config );

BEGIN {
    require FindBin;
    $sl_root = "$FindBin::RealBin/../";
    if ( !-d "$sl_root/conf" ) {

        # no conf directory, try using $ENV{SL_ROOT} for $sl_root
        die "Couldn't set \$sl_root" unless ( $ENV{SL_ROOT} );
        $sl_root = $ENV{SL_ROOT};
    }
}

use base 'Config::ApacheFormat';

sub new {
    my ( $class, $config_files_ref ) = @_;

    return $config if $config;

    unless ($config_files_ref) {

        # use the developer's config file if it exists
        if ( -e "$sl_root/sl.conf" ) {
            push @{$config_files_ref}, "$sl_root/sl.conf";
        }

        # if no default config, or dev config found we can't do anything
        if (   ( !$config_files_ref )
            && ( !-e "$sl_root/conf/sl.conf" ) )
        {
            require Carp
              && Carp::croak(
                    "No $sl_root/sl.conf or $sl_root/conf/sl.conf present, "
                  . "did you symlink the conf directory to the httpd root?"
                  . "\nOr forget to set the environment variable SL_ROOT?" );
        }
        elsif ( -e "$sl_root/conf/sl.conf" ) {

            # if there is a default config setup use it
            unshift @{$config_files_ref}, "$sl_root/conf/sl.conf";
        }
    }

    # we have a configuration file to work with, so get to work
    $config = $class->SUPER::new();
    my $read;
    foreach my $config_file ( @{$config_files_ref} ) {
        next unless ( -e $config_file );
        $config->read($config_file);
        $read++;
    }

    unless ($read) {
        require Data::Dumper;
        require Carp
          && Carp::croak( "No config files read: "
              . Data::Dumper::Dumper($config_files_ref) );
    }

    $config->autoload_support(1);
    return $config;
}

=item C<sl_db_params>

Returns an array reference

=cut

sub sl_db_params {
    my $self = shift;

}

sub tmpl_root {
    my $self = shift;
    return $self->sl_root . '/' . $self->sl_version . '/tmpl';
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