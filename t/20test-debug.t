#!/usr/bin/env perl
use warnings; use strict;
use rlib '.'; use Helper;

my $test_prog = prog_file('gcd.pl');

my $opts = {
    filter => sub{
	my ($got_lines, $correct_lines) = @_;
	my @result = ();
	for my $line (split("\n", $got_lines)) {
	    $line =~ s/main::\(.* remapped \(eval \d+\).+\]:(\d+)/main::(bogus.pl remapped (eval 1955)[Eval.pm:$1]/;
	    # $line =~ s/\((?:.*\/)?(.+\:\d+)\)/($1)/;
	    push @result, $line;
	}
	$got_lines = join("\n", @result);
	return ($got_lines, $correct_lines);
    },
    run_opts => " --no-highlight --basename -nx"
};

run_debugger("$test_prog 3 5", cmd_file(), undef, $opts);
done_testing();
