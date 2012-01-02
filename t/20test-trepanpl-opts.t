#!/usr/bin/env perl
use strict;
use warnings; use strict;
use English qw( -no_match_vars );
use Config;
use File::Basename;
use File::Spec;
my $trepanpl = File::Spec->catfile(dirname(__FILE__), qw(.. bin trepan.pl));

use Test::More;
note( "trepan.pl command options" );

# rlib seems to flip out if it can't find trepan.pl
my $dirname = dirname(__FILE__);
my $bin_dir = File::Spec->catfile($dirname, '..', 'bin');
$ENV{PATH} = $bin_dir . $Config{path_sep} . $ENV{PATH};

if( $Test::More::VERSION >= 1.0 ) {
    plan skip_all => "STO's smokers cause weird problems";
} else {
    plan 'no_plan';
}

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
