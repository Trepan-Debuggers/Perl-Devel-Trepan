#!/usr/bin/env perl
use warnings; use strict;
use rlib '.';
use Helper;
my $test_prog = File::Spec->catfile(dirname(__FILE__), qw(.. example gcd.pl));
use Test::More 'no_plan';

my $full_cmdfile = File::Spec->catfile(dirname(__FILE__), 'data', 'eval2.cmd');
my $opts = {
    filter => sub{
	my ($got_lines, $correct_lines) = @_;
	my @result = ();
	for my $line (split("\n", $got_lines)) {
	    if ($line =~ /.. \(eval \d+\).+ remapped .+:\d+\)/) {
		$line =~ s/\(eval \d+\).+ remapped .+:(\d+)\)/(eval remapped $1)/;
	    } elsif ($line =~ /.. \(.+\:\d+\)/) {
		$line =~ s/\((?:.*\/)?(.+\:\d+)\)/($1)/;
	    }
	    push @result, $line;
	}
	$got_lines = join("\n", @result);
	return ($got_lines, $correct_lines);
    },
    run_opts => " --no-highlight --basename -nx"
};

Helper::run_debugger("$test_prog 3 5", 'debug.cmd', undef, $opts)
