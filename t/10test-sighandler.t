#!/usr/bin/env perl

use strict; use warnings;
use English qw( -no_match_vars );

use rlib '../lib';

use Test::More;
note( "Testing Devel::Trepan::SigHandler" );

BEGIN {
    use_ok( 'Devel::Trepan::SigHandler' );
}

import Devel::Trepan::SigHandler;

for my $signum (0.. scalar(keys(%SIG))-1) {
    my $signame = Devel::Trepan::SigMgr::lookup_signame($signum);
    if (defined $signame) {
        is(Devel::Trepan::SigMgr::lookup_signum($signame), $signum);
        # Try with the SIG prefix
        is(Devel::Trepan::SigMgr::lookup_signum('SIG' . $signame), $signum);
    }
}


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

sub mysighandler($) {
    my $num = shift; 
    print "Signal $num caught\n";  
}

sub myprint($) { 
    my $msg = shift; 
    print "$msg\n";  
}

my $h = Devel::Trepan::SigMgr->new(\&mysighandler, \&myprint);
done_testing();
