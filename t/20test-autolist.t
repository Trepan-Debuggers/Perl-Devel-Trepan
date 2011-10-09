#!/usr/bin/env perl
use warnings; use strict;
use File::Basename; use File::Spec;
use Test::More 'no_plan';
use lib dirname(__FILE__);
use Helper;
my $test_prog = File::Spec->catfile(dirname(__FILE__), 
				    qw(.. example gcd.pl));
Helper::run_debugger("$test_prog 3 5", 'autolist.cmd');
