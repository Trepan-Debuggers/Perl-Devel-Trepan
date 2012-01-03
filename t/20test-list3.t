#!/usr/bin/env perl                                                             
use warnings; use strict;
use File::Basename;
use Test::More;
if ($File::Basename::VERSION <= 2.74) {
    plan skip_all => "Need File::Basename version 2.75 or greater"
} else {
    plan 'no_plan';
}

use rlib '.';
use Helper;
my $test_prog = File::Spec->catfile(dirname(__FILE__),
                                    qw(.. example test-require.pl));
Helper::run_debugger("$test_prog", 'list3.cmd');
