# /etc/skel/.bash_profile:
# $Header: /var/cvsroot/gentoo-src/rc-scripts/etc/skel/.bash_profile,v 1.11 2004/07/22 02:34:08 agriffis Exp $

# This file is sourced by bash for login shells.  The following line
# runs your .bashrc and is recommended by the bash info pages.
[[ -f ~/.bashrc ]] && . ~/.bashrc

export SL_ROOT=/home/fred/dev/sl/tags/sl5
export PERL5LIB=$SL_ROOT/lib
export PATH=~/dev/perl/bin:$SL_ROOT/bin:$SL_ROOT/../../httpd2/bin:$PATH
