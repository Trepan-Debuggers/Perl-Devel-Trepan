#!/usr/bin/env perl
use warnings; use strict;
use rlib '.'; use Helper;
use English qw( -no_match_vars );

if ($OSNAME eq 'MSWin32') {
    plan skip_all => "Strawberry Perl has trouble here and I can't get info to fix" 
} else {
    plan;
}

my $test_prog = prog_file('gcd.pl');

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
	    } elsif ($line =~ /^Use 'info file/) {
		$line = "Use 'info file XXX brkpts' to see breakpoints I know about";
		push @result, $line;
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
run_debugger("$test_prog 3 5", 'break.cmd', undef, $opts);

$test_prog = prog_file('TCPPack.pm');
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

run_debugger("$test_prog", 'break2.cmd', undef, $opts);
done_testing();
