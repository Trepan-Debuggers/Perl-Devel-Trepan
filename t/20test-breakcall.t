#!/usr/bin/env perl
use warnings; use strict;
use rlib '.'; use Helper;
use English qw( -no_match_vars );

my $test_prog = prog_file('callbug.pl');

my $opts = {
    run_opts => " --no-highlight --basename -nx --testing"
};
run_debugger("$test_prog foo", 'breakcall.cmd', undef, $opts);
done_testing();
