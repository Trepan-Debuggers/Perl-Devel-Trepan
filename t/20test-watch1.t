#!/usr/bin/env perl
use warnings; use strict;
use Test::More;
use rlib '.';
use Helper;
my $test_prog = File::Spec->catfile(dirname(__FILE__), 
				    qw(.. example gcd.pl));
Helper::run_debugger("$test_prog 5 3", 'watch1.cmd');
Helper::run_debugger("$test_prog 3 5", 'watch2.cmd');
done_testing();
