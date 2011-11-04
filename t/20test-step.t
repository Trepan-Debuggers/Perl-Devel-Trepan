#!/usr/bin/env perl
use warnings; use strict;
use Test::More 'no_plan';
use relative_lib '.';
use Helper;
my $test_prog = File::Spec->catfile(dirname(__FILE__), 
				    qw(.. example nexting.pl));
Helper::run_debugger("$test_prog", 'step.cmd');
