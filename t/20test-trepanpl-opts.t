#!/usr/bin/env perl
use warnings; use strict;
use English qw( -no_match_vars );
use Config;
use File::Basename; use File::Spec;
my $dirname = dirname(__FILE__);
my $trepanpl = File::Spec->catfile($dirname, qw(.. bin trepan.pl));

use Test::More;
note( "trepan.pl command options" );

if( $Test::More::VERSION > 0.9802 ) {
    plan skip_all => "Test::More::VERSION > 0.9802 causes weird problems";
    exit 0;
}

# rlib seems to flip out if it can't find trepan.pl
my $bin_dir = File::Spec->catfile($dirname, '..', 'bin');
$ENV{PATH} = $bin_dir . $Config{path_sep} . $ENV{PATH} if -d $bin_dir;

is(-r $trepanpl, 1, "Should be able to read trepan.pl program $trepanpl");

# FIXME: in child save output to a temporary file. Then in the parent
# do the tests.
use File::Temp qw(tempfile);
my ($fh, $tempfile) = tempfile('optsXXXX', UNLINK=> 1, TMPDIR => 1);

my $output;
local $/;              # enable "slurp" mode
my $pid = fork();
if ($pid) {
    waitpid($pid, 0);
    is(1, $CHILD_ERROR >> 8);
    open($fh, '<', $tempfile);
    $output = <$fh>;    # read whole file
    like($output, qr/Usage:/, "$trepanpl --help should have a 'usage line");
} else {
    my $output = `$EXECUTABLE_NAME -- $trepanpl --help`;
    my $rc = $? >> 8;
    print $fh $output;
    close $fh;
    exit $rc;
}

$pid = fork();
if ($pid) {
    waitpid($pid, 0);
    is($CHILD_ERROR >> 8, 10);
    open($fh, '<', $tempfile);
    $output = <$fh>;    # read whole file
    like($output, qr/, version /, 
	 "$trepanpl --version should be able to show the version number");
} else {
    my $output = `$EXECUTABLE_NAME -- $trepanpl --version`;
    my $rc = $? >> 8;
    open($fh, '>', $tempfile);
    print $fh $output;
    close $fh;
    exit $rc;
}

done_testing();
