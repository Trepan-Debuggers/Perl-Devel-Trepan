#!/usr/bin/env perl
use warnings; use strict; use English qw( -no_match_vars );
use Test::More;
use rlib '.'; use Helper;

my $test_prog = prog_file('gcd.pl');

my $opts = {
    filter => sub{
        my ($got_lines, $correct_lines) = @_;
        my @result = ();
	my $skip = 0;
        foreach (split("\n", $got_lines)) {
	    s/^\s+'/  '/;
	    s/^\s*\]/  ]/;
	    s/^\s*\}/}/;
            push @result, $_;
        }
        $got_lines = join("\n", @result);
        return ($got_lines, $correct_lines);
    },
    run_opts => " --no-highlight --basename -nx --fall-off-end"
};

run_debugger("$test_prog 3 5", cmd_file(), undef, $opts);
$test_prog = prog_file('eval.pl');

$opts = {
    filter => sub{
        my ($got_lines, $correct_lines) = @_;
        my @result = ();
	my $skip = 0;
        foreach (split("\n", $got_lines)) {
	    if ($skip) {
		$skip--; 
		next;
	    }
            # if (/main::\(\(eval .+:\d+\).* remapped /) {
            if (/main::\(\(eval .+:\d+.* remapped /) {
                s/main::\(\(eval .+:\d+.* remapped (?:.+):(\d+)/main::((eval 1955)[eval.pl:10]:$1 remapped bogus.pl:$1/;
            } elsif (/.. \(.+\:\d+\)/) {
                if ($OSNAME eq 'MSWin32') {
                    s/\((?:.+\\)?(.+\:\d+)\)/($1)/;
                } else {
                    s/\((?:.+\/)?(.+\:\d+)\)/($1)/;
                }
            } elsif (/`\(eval \d+\)\[.+:13\]'/) {
                s/`\(eval \d+\)\[.+:13\]'/`(eval 1000)[eval.pl:13]'/;
            } elsif (/^sub five/) {
                # Perl 5.10.0 doesn't show "sub five() {"
		$skip = 3;
                next;
            } elsif ( /^\s*\}/ ) {
                next;
	    }
            push @result, $_;
        }
        $got_lines = join("\n", @result);
        return ($got_lines, $correct_lines);
    },
    run_opts => " --no-highlight --basename -nx --fall-off-end"
};

run_debugger("$test_prog", 'eval2.cmd', undef, $opts);
done_testing();
