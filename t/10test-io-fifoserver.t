#!/usr/bin/env perl
use strict; use warnings;
use English qw( -no_match_vars );
use rlib '../lib';
use Config;

use Test::More;
if ($OSNAME eq 'MSWin32' or $OSNAME eq 'msys') {
    plan skip_all => 'FIXME make work on MinGW and Strawberry Perl?'
} else {
    plan;
}

note( "Testing Devel::IO::FIFOServer" );

require_ok( 'Devel::Trepan::IO::FIFOServer' );

note "Testing FIFO server open";
my $pid = fork();
if ($pid == 0) {
    my $inout = Devel::Trepan::IO::FIFOServer->new();
    my $rc = $? >> 8;
    exit $rc;
} else {
    waitpid($pid, 0);
    is($?>>8, 0);
}

done_testing();
