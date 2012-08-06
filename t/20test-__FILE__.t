#!/usr/bin/env perl
use warnings; use strict;
use rlib '.';
use Helper;
no warnings 'redefine';

my $opts = {
    filter => sub{
	my ($got_lines, $correct_lines) = @_;
	my @result = ();
	for my $line (split("\n", $got_lines)) {
	    $line =~ s/['"].*gcd.pl["']/"gcd.pl"/;
	    $line =~ s/['"]18["']/18/;
	    push @result, $line;
	}
	$got_lines = join("\n", @result) . "\n";
	return ($got_lines, $correct_lines);
    },
    run_opts => " --basename --no-highlight -nx"
};

my $test_prog = File::Spec->catfile(dirname(__FILE__), qw(.. example gcd.pl));
use Test::More;
Helper::run_debugger("$test_prog 3 5", '__FILE__.cmd', undef, $opts);
done_testing();
