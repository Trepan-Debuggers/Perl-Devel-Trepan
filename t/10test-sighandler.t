#!/usr/bin/env perl

use strict; use warnings;
use English qw( -no_match_vars );

use rlib '../lib';

use Test::More 'no_plan';
note( "Testing Devel::Trepan::SigHandler" );

BEGIN {
    use_ok( 'Devel::Trepan::SigHandler' );
}

import Devel::Trepan::SigHandler;

for my $pair ([15, 'TERM'], [-15, 'TERM'], [300, undef]) {
    my ($i, $expect) = @$pair;
    is(Devel::Trepan::SigMgr::lookup_signame($i), $expect);
}
    
for my $pair (['term', 15], ['TERM', 15], ['NotThere', undef]) {
    my ($sig, $expect) = @$pair;
    is(Devel::Trepan::SigMgr::lookup_signum($sig), $expect);
}
    
for my $pair (['15', 'TERM'], ['-15', 'TERM'], ['term', 'TERM'], 
	   ['sigterm', 'TERM'], ['TERM', 'TERM'], ['300', undef], 
	   ['bogus', undef]) {
    my ($i, $expect) = @$pair;
    is(Devel::Trepan::SigMgr::canonic_signame($i), $expect);
}
