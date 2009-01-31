#!/usr/bin/perl

use strict;
use warnings;

use Mail::Mailer;

my $support = "SLN Support <support\@silverliningnetworks.com>";

 
       `ps aux | grep postgres | wc -l > count`;

        unless (open(FILE, "count")) {

               die ("cannot open file count \n");

        }

        my $number = <FILE>;

        print $number;

        if ($number > 250) {

           my $mailer  = Mail::Mailer->new('qmail'); 
           
           my $mailmssg = "POSTGRES PROCESSES EXCEEDED 250";

           $mailer->open(
              {
                  'From'      => $support,
                  'To'    => $support,
                  'Subject' => " POSTGRES PROCESSES EXCEEDED 250 ",
              }
           );
           print $mailer $mailmssg;
          
           $mailer->close();

           } 

       
