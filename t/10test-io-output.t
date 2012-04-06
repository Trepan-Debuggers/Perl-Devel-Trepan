#!/usr/bin/env perl
use strict;
use warnings;
use rlib '../lib';

use Test::More 'no_plan';
note( "Testing Devel::Trepan::IO::Output" );

BEGIN {
use_ok( 'Devel::Trepan::IO::Output' );
}

# use IO::String;
# my $io_out = new IO::String->new();
# *STDOUT = $io_out;
my $out = Devel::Trepan::IO::Output->new();
close(STDOUT);
## FIXME: figure out how to test this...
# Should see the next line
$out->writeline("Now is the time!");
