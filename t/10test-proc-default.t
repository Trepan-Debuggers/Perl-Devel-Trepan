#!/usr/bin/env perl
use strict; use warnings; no warnings 'redefine';
use rlib '../lib';
use vars qw($response); 

use Test::More 'no_plan';

BEGIN {
note( "Testing Devel::Trepan::CmdProcessor::Default" );
use_ok( 'Devel::Trepan::CmdProcessor::Default' );
}

my $print_types = 1;
$print_types ++ if $Devel::Trepan::CmdProcessor::HAVE_DATA_PRINT;
$print_types ++ if $Devel::Trepan::CmdProcessor::HAVE_PERLTIDY;
is($print_types, scalar @Devel::Trepan::CmdProcessor::DISPLAY_TYPES, 
   '@DISPLAY_TYPES should match count of HAVE_DATA_PRINT and HAVE_PERLTIDY');

