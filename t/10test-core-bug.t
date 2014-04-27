#!/usr/bin/env perl
use strict; use warnings;
no warnings 'redefine'; no warnings 'once';
use rlib '../lib';

use Test::More;
note( "Testing Devel::Core" );

my $orig = $0;
require Devel::Trepan::Core;
note("Make sure we're not munging $0 by requiring debugger (Core)");
is($0, $orig);

done_testing();
