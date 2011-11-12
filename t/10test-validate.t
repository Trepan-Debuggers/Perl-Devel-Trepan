#!/usr/bin/env perl
use strict;
use warnings;
use rlib '../lib';

use Test::More 'no_plan';
note( "Testing Devel::Trepan::CmdProcessor::Validate" );

BEGIN {
use_ok( 'Devel::Trepan::CmdProcessor::Validate' );
}

import Devel::Trepan::CmdProcessor;

note 'Test get onoff';

for my $pair (['1', 1],  ['on',  1],
	      ['0', 0],  ['off', 0]) {
    my ($arg, $expected) = ($pair->[0], $pair->[1]);
    is(Devel::Trepan::CmdProcessor::get_onoff('bogus', $arg), $expected, 
	"onoff of \"$arg\" should be $expected");
}
    
note 'Test get_int_noerr';

for my $pair (['1',     1],  ['on',  undef],
	      ['+0',    0],  ['1024', 1024],
	      ['12  ', 12],  ['ab12', undef],
	      ['1+2',   3], 
    ) {
    my ($arg, $expected) = ($pair->[0], $pair->[1]);
    my $print_val = defined $expected ? $expected : 'undef';
    is(Devel::Trepan::CmdProcessor::get_int_noerr('bogus', $arg), $expected, 
	"get_int_noerr of \"$arg\" should be $print_val");
}
    
