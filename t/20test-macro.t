#!/usr/bin/env perl
use warnings; use strict;
use rlib '.'; use Helper;

my $test_prog = prog_file('gcd.pl');
run_debugger("$test_prog 3 5");
done_testing();
