#!/usr/bin/env perl
use warnings; use strict;
use Test::More 'no_plan';
use rlib '.';
use Helper;
my $test_prog = File::Spec->catfile(dirname(__FILE__), 
				    qw(.. example test-require.pl));
Helper::run_debugger("$test_prog", 'list3.cmd');
