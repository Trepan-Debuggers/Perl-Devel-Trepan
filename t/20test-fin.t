#!/usr/bin/env perl
use warnings; use strict;
use rlib '.';
use Helper;
no warnings 'redefine';
my $test_prog = File::Spec->catfile(dirname(__FILE__), qw(.. example TCPPack.pm));
use Test::More;
Helper::run_debugger("$test_prog", 'fin.cmd');
$test_prog = File::Spec->catfile(dirname(__FILE__), qw(.. example gcd.pl));
Helper::run_debugger("$test_prog 3 5", 'fin2.cmd');
done_testing();
