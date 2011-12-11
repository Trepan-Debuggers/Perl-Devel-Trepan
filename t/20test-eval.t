#!/usr/bin/env perl
use warnings; use strict; use English;
use Test::More 'no_plan';
use rlib '.';
use Helper;
my $test_prog = File::Spec->catfile(dirname(__FILE__), 
				    qw(.. example gcd.pl));
Helper::run_debugger("$test_prog 3 5", 'eval.cmd');
$test_prog = File::Spec->catfile(dirname(__FILE__), 
				    qw(.. example eval.pl));

my $full_cmdfile = File::Spec->catfile(dirname(__FILE__), 'data', 'eval2.cmd');
my $opts = {
    filter => sub{
	my ($got_lines, $correct_lines) = @_;
	my @result = ();
	for my $line (split("\n", $got_lines)) {
	    if ($line =~ /.. \(eval \d+\).+ remapped .+:\d+\)/) {
		$line =~ s/\(eval \d+\).+ remapped .+:(\d+)\)/(eval remapped $1)/;
	    } elsif ($line =~ /.. \(.+\:\d+\)/) {
		if ($OSNAME eq 'MSWin32') {
		    $line =~ s/\((?:.+\\)?(.+\:\d+)\)/($1)/;
		} else {
		    $line =~ s/\((?:.+\/)?(.+\:\d+)\)/($1)/;
		}
	    } elsif ($line =~ /`\(eval \d+\)\[.+:12\]'/) {
		$line =~ s/`\(eval \d+\)\[.+:12\]'/`(eval 1000)[eval.pl:12]'/;
	    }     
	    push @result, $line;
	}
	$got_lines = join("\n", @result);
	return ($got_lines, $correct_lines);
    },
    run_opts => " --no-highlight --basename -nx"
};

Helper::run_debugger("$test_prog", 'eval2.cmd', undef, $opts);
