#!/usr/bin/env perl
use warnings; use strict;
use rlib '.'; use Helper;

my $opts = {
    filter => sub{
	my ($got_lines, $correct_lines) = @_;
	return ($got_lines, $correct_lines);
    },
    run_opts => " --basename --no-highlight -nx --fall-off-end"
};

my $test_prog = prog_file('gcd.pl');
run_debugger("$test_prog 3 5", cmd_file(), undef, $opts);
done_testing();
