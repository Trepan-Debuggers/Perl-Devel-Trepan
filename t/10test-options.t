#!/usr/bin/env perl
use strict; use warnings; use English;
use lib '../lib';

use Test::More 'no_plan';
note( "Testing Devel::Trepan::Options" );

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
isnt(whence_file('perl'), 'perl',
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
