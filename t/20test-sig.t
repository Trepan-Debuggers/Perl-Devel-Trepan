#!/usr/bin/env perl
use warnings; use strict;
use English;
use rlib '.';
use Helper;
if ($OSNAME eq 'MSWin32') {
    eval "use Test::More skip_all => 
     'Strawberry Perl might not handle signals properly'";
}

diag("FIXME: redo with File::Temp. Also, I think there's a bug in the sig2.cmd test.");

my $test_prog = File::Spec->catfile(dirname(__FILE__), 
				    qw(.. example signal.pl));
my $tempfile = "/tmp/signal.$$";
my $pid = fork();
if ($pid) {
    eval "use Test::More 'no_plan';";
    sleep 1 until -r $tempfile;
    open (my $fh, '<', $tempfile) or die $OS_ERROR;
    my $kill_pid = <$fh>;
    chomp $kill_pid;
    kill('HUP', $kill_pid);
    waitpid($pid, 0);
    is($CHILD_ERROR >> 8, 0);
} else {
    print "running $test_prog\n";
    my $opts = {do_test => 0};
    my $ok = Helper::run_debugger("$test_prog $tempfile", 'sig.cmd', undef, 
				  $opts);
    exit $ok;
}

$pid = fork();
if ($pid) {
    sleep 1 until -r $tempfile;
    open (my $fh, '<', $tempfile) or die $OS_ERROR;
    my $kill_pid = <$fh>;
    chomp $kill_pid;
    kill('HUP', $kill_pid);
    waitpid($pid, 0);
    is($CHILD_ERROR >> 8, 0);
    chdir '/tmp';
    is(unlink($tempfile), 1);
} else {
    print "running $test_prog\n";
    my $opts = {do_test => 0};
    my $ok = Helper::run_debugger("$test_prog $tempfile", 'sig2.cmd', undef, 
				  $opts);
    exit $ok;
}
