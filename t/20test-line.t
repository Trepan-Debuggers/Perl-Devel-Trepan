#!/usr/bin/env perl
use warnings; use strict;
use rlib '.'; use Helper;

my $opts = {
    filter => sub{
	my ($got_lines, $correct_lines) = @_;
	my @result = ();
	for my $line (split("\n", $got_lines)) {
	    $line =~ s/^OP address: 0x[0-9a-f]+\.$/OP address: 0x12345678./;
	    push @result, $line;
	}
	$got_lines = join("\n", @result) . "\n";
	return ($got_lines, $correct_lines);
    },
    run_opts => " --basename --no-highlight -nx --fall-off-end"
};

my $test_prog = prog_file('gcd.pl');
run_debugger("$test_prog 3 5", undef, undef, $opts);
done_testing();
