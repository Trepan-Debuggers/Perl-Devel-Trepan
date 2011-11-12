#!/usr/bin/env perl
use warnings; use strict;
use rlib '.';
use Helper;
my $test_prog = File::Spec->catfile(dirname(__FILE__), qw(.. example gcd.pl));
use Test::More 'no_plan';
Helper::run_debugger("$test_prog 3 5", 'break.cmd')
