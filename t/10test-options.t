#!/usr/bin/env perl

use strict; use warnings;
use English qw( -no_match_vars );

use rlib '../lib';

use Test::More;
note( "Testing Devel::Trepan::Options" );

if( $Test::More::VERSION >= 1.0 ) {
    plan skip_all => "Test::More::VERSION >= 1.0 causes weird problems";
} else {
    plan 'no_plan';
}


BEGIN {
    use_ok( 'Devel::Trepan::Options' );
}

import Devel::Trepan::Options;

note 'Test whence_file';
for my $not_found_program 
    (qw(./bogus/program ../bogus/program /bogus/program)) {
	is(whence_file($not_found_program), $not_found_program,
	   "when program ${not_found_program} is not found, it is unchanged");
}

my $perl = ($OSNAME eq 'MSWin32') ? 'perl.exe' : 'perl';
isnt(whence_file($perl), $perl,
    "We should be able to find perl in your path");
is(whence_file($EXECUTABLE_NAME), $EXECUTABLE_NAME,
   "Perl binary ${EXECUTABLE_NAME} is generally absolute and should be unchanged");

note 'Test get_options';
my $pid = fork();
if ($pid == 0) {
    my @argv = qw(--version);
    my $opts = process_options(\@argv);
    exit 0;
} else {
    waitpid($pid, 0);
    isnt($?>>8, 0);
}

note 'Test --batch option';
$pid = fork();
if ($pid == 0) {
    my @argv = ('--batch', __FILE__);
    my $opts = process_options(\@argv);
    ($opts->{batchfile} eq __FILE__) ? exit 0 : exit 10;
} else {
    waitpid($pid, 0);
    is($?>>8, 0);
}

