#!/usr/bin/perl

use strict;
use warnings;

use 5.008008;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME         => 'SL-Payment',
    VERSION_FROM => 'lib/SL/Payment.pm',
    PREREQ_PM    => {
        'Business::OnlinePayment::AuthorizeNet' => 3.20,
        'SL::Model'                             => 0.18,
    },
    ABSTRACT => 'Silver Lining Payment abstraction',
    AUTHOR   => 'Fred Moyer <fred@silverliningnetworks.com>',
);
