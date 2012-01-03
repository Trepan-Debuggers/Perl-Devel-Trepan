#!/usr/bin/env perl
use warnings; use strict;
use rlib '.';
use Helper;
my $test_prog = File::Spec->catfile(dirname(__FILE__), qw(.. example gcd.pl));
use Test::More 'no_plan';
my $opts = {
    filter => sub{
	my ($got_lines, $correct_lines) = @_;
	my @result = ();
	my $skip_next = 0;
	for my $line (split("\n", $got_lines)) {
	    if ($line =~ /matched debugger cache file:/) {
		$line = 'XXXX matched debugger cache file:';
		push @result, ($line, "\tgcd.pl");
		$skip_next = 1;
		next;
	    } elsif ($line =~ /Line 10 of/) {
		push(@result, 
		     '*** Line 10 of XXX not known to be a trace line.');
	    } else {
		push @result, $line unless $skip_next;;
		$skip_next = 0;
	    }
	}
	$got_lines = join("\n", @result);
	return ($got_lines, $correct_lines);
    },
    run_opts => " --no-highlight --basename -nx --testing"
};
Helper::run_debugger("$test_prog 3 5", 'break.cmd', undef, $opts);

$test_prog = File::Spec->catfile(dirname(__FILE__), 
				 qw(.. example TCPPack.pm));
$opts = {
    filter => sub{
	my ($got_lines, $correct_lines) = @_;
	my @result = ();
	for my $line (split("\n", $got_lines)) {
	    if ($line =~ /Breakpoint 1 set in Exporter\.pm at line/) {
		push (@result, 
		      'Breakpoint 1 set in Exporter.pm at line 29');
	    } elsif ($line =~ /^1   breakpoint    keep y   at Exporter\.pm/) {
		push(@result,  
		     '1   breakpoint    keep y   at Exporter.pm:29');
	    } else {
		push @result, $line;
	    }
	}
	$got_lines = join("\n", @result);
	return ($got_lines, $correct_lines);
    },
    run_opts => " --no-highlight --basename -nx --testing"
};

Helper::run_debugger("$test_prog", 'break2.cmd', undef, $opts);
