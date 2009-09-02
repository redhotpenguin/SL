#!/bin/sh

dbicdump -o dump_directory=/tmp \
           -o debug=1 \
           SL::Model::App \
           'dbi:Pg:dbname=sl_prod' \
          phred

