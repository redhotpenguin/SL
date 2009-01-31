#!/usr/bin/perl

use strict;
use warnings;

use Mail::Mailer;

my $support = "SLN Support <support\@silverliningnetworks.com>";

 
       `ps aux | grep -c httpd > count_httpd`;

        unless (open(FILE, "count_httpd")) {

               die ("cannot open file count \n");

        }

        my $number = <FILE>;

        print $number;

        if ($number > 250) {

           my $mailer  = Mail::Mailer->new('qmail'); 
           
           my $mailmssg = "HTTPD PROCESSES EXCEEDED 250";

           $mailer->open(
              {
                  'From'      => $support,
                  'To'    => $support,
                  'Subject' => " HTTPD PROCESSES EXCEEDED 250 ",
              }
           );
           print $mailer $mailmssg;
          
           $mailer->close();

           } 

       
