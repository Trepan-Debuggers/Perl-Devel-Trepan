#!/usr/bin/env perl
use warnings; use strict; use English;
use Test::More;
use rlib '.'; use Helper;

my $test_prog = prog_file('gcd.pl');
run_debugger("$test_prog 3 5", cmd_file());
$test_prog = prog_file('eval.pl');

my $opts = {
    filter => sub{
	my ($got_lines, $correct_lines) = @_;
	my @result = ();
	for my $line (split("\n", $got_lines)) {
	    if ($line =~ /remapped \(eval .+:\d+\)/) {
		#use Enbugger; Enbugger->load_debugger('trepan'); Enbugger->stop;
		$line =~ s/main::\(.* remapped \(eval \d+\)\[.+\]:(\d+)/main::(bogus.pl remapped (eval 1955)[eval.pl:10]:$1/;
	    } elsif ($line =~ /.. \(.+\:\d+\)/) {
		if ($OSNAME eq 'MSWin32') {
		    $line =~ s/\((?:.+\\)?(.+\:\d+)\)/($1)/;
		} else {
		    $line =~ s/\((?:.+\/)?(.+\:\d+)\)/($1)/;
		}
	    } elsif ($line =~ /`\(eval \d+\)\[.+:12\]'/) {
		$line =~ s/`\(eval \d+\)\[.+:12\]'/`(eval 1000)[eval.pl:12]'/;
	    } elsif ($line =~ /^sub five/) {
		# Perl 5.10.0 doesn't show "sub five() {"
		next;
	    }     
	    push @result, $line;
	}
	$got_lines = join("\n", @result);
	return ($got_lines, $correct_lines);
    },
    run_opts => " --no-highlight --basename -nx --fall-off-end"
};

run_debugger("$test_prog", 'eval2.cmd', undef, $opts);
done_testing();
