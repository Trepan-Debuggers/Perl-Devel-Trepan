#!/usr/bin/env perl
use strict;
use warnings; use strict;
use English;
use File::Basename;
use File::Spec;
my $trepanpl = File::Spec->catfile(dirname(__FILE__), qw(.. bin trepanpl));

use Test::More 'no_plan';
note( "trepanpl command options" );
is(-r $trepanpl, 1, "Should be able to read trepanpl program");

my $pid = fork();
if ($pid) {
    waitpid($pid, 0);
    is(1, $CHILD_ERROR >> 8);
} else {
    my $output = `$EXECUTABLE_NAME -- $trepanpl --help`;
    my $rc = $? >> 8;

# FIXME: Including messes up TAP numbering in parent.
#    cmp_ok($output =~ /Usage:/, '>', 0, 
#	   "$trepanpl --help should have a 'usage line");

    exit $rc;
}

$pid = fork();
if ($pid) {
    waitpid($pid, 0);
    is($CHILD_ERROR >> 8, 10);
} else {
    my $output = `$EXECUTABLE_NAME -- $trepanpl --version`;
    my $rc = $? >> 8;
# FIXME: Including messes up TAP numbering in parent.
#    cmp_ok($output =~ /, version /, '>', 0,
#	   "$trepanpl --version should be able to show the version number");
    exit $rc;
}
