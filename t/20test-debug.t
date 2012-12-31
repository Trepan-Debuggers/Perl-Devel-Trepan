#!/usr/bin/env perl
use warnings; use strict;
use rlib '.'; use Helper;

my $test_prog = prog_file('gcd.pl');

my $opts = {
    filter => sub{
	my ($got_lines, $correct_lines) = @_;
	my @result = ();
	for (split("\n", $got_lines)) {
	    s/main::\(\(eval .+:\d+.* remapped (?:.+):(\d+)/main::((eval 1955)[Eval.pm:73]:$1 remapped bogus.pl:$1/;
	    # $line =~ s/\((?:.*\/)?(.+\:\d+)\)/($1)/;
	    push @result, $_;
	}
	$got_lines = join("\n", @result);
	return ($got_lines, $correct_lines);
    },
    run_opts => " --no-highlight --basename -nx"
};

run_debugger("$test_prog 3 5", undef, undef, $opts);
done_testing();
