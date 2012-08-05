#!/usr/bin/env perl
use warnings; use strict;
use rlib '.';
use Helper;

my $opts = {
    filter => sub{
	my ($got_lines, $correct_lines) = @_;
	my @result = ();
	for my $line (split("\n", $got_lines)) {
	    if ($line =~ /'gcd.pl'/) {
		$line =~ s/'gcd.pl'/"gcd.pl"/;
	    }
	    push @result, $line;
	}
	$got_lines = join("\n", @result) . "\n";
	return ($got_lines, $correct_lines);
    },
    run_opts => " --basename --no-highlight -nx"
};


my $test_prog = File::Spec->catfile(dirname(__FILE__), qw(.. example gcd.pl));
use Test::More;
Helper::run_debugger("$test_prog 3 5", 'dollar0.cmd', undef, $opts);
done_testing();
