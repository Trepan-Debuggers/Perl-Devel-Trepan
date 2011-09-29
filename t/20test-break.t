#!/usr/bin/env perl
use warnings; use strict;
use English;
use File::Basename; use File::Spec;
use String::Diff;
use Test::More 'no_plan';

my $trepanpl = File::Spec->catfile(dirname(__FILE__), qw(.. bin trepanpl));
my $debug = $^W;
sub run_trepanpl($$;$)
{
    my ($test_invoke, $cmdfile, $rightfile) = @_;
    ($rightfile = $cmdfile) =~ s/.cmd/.right/ unless defined($rightfile);
    my $opts = "--basename --nx --no-highlight";
    my $cmd = "$EXECUTABLE_NAME $trepanpl $opts --command $cmdfile $test_invoke";
    note( "running $test_invoke with $cmdfile" );
    print $cmd, "\n" if $debug;
    my $output = `$cmd`;
    print $output if $debug;
    my $rc = $? >> 8;
    is($rc, 0);
    open(RIGHT_FH, "<$rightfile");
    undef $INPUT_RECORD_SEPARATOR;
    my $right_string = <RIGHT_FH>;
    if ($right_string eq $output) {
	ok(1);
    } else {
	my $diff = String::Diff::diff_merge($output, $right_string);
	print $diff;
	ok(0, "Output comparison fails");
    }
}

my $test_prog = File::Spec->catfile(dirname(__FILE__), qw(.. example gcd.pl));
my $cmdfile = File::Spec->catfile(dirname(__FILE__), qw(data break.cmd));
run_trepanpl("$test_prog 3 5", $cmdfile);
