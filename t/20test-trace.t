#!/usr/bin/env perl
use warnings; use strict;
use rlib '.'; use Helper;

my $full_cmdfile = File::Spec->catfile(dirname(__FILE__), 'data', 'trace1.cmd');
my $opts = {
    filter => sub{
	my ($got_lines, $correct_lines) = @_;
	my @result = ();
	for my $line (split("\n", $got_lines)) {
	    $line =~ s/\((?:.*\/)?(.+\:\d+)\)/($1)/;
	    last if (0 == index($line, '-- Devel::Trepan::Core::(Core.pm:'));
	    push @result, $line;
	}

	# Eval::WithLexicals adds a couple of extra lines. Remove
	# these for comparison so we can handle installations that
	# don't have Eval::WithLexicals.
	@result = splice(@result, 0, -2) if 
	    $result[-1] eq 'END { $_in_global_destruction = 1 }';

	# Some of SREZIC's smokers add a couple of lines in
	# remapping _Utils.pm:95
	@result = splice(@result, 0, -2) if $result[-2] =~ /remap/;


	$got_lines = join("\n", @result);
	return ($got_lines, $correct_lines);
    },
    no_cmdfile => 1,
    run_opts => " --trace --basename --no-highlight -nx --fall-off-end"
};

my $test_prog = prog_file('gcd.pl');
run_debugger("$test_prog 3 5", 'trace1.cmd', undef, $opts);
$opts->{no_cmdfile} = 0;
$opts->{run_opts}   = " --no-highlight --nx --basename --fall-off-end";
run_debugger("$test_prog 3 5", 'trace2.cmd', undef, $opts);
done_testing();
