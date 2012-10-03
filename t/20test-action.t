#!/usr/bin/env perl
use warnings; use strict;
use Test::More;
use rlib '.';
use Helper;
my $test_prog = File::Spec->catfile(dirname(__FILE__), 
				    qw(.. example action-bug.pl));
Helper::run_debugger("$test_prog", 'action.cmd');
done_testing();
