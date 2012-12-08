#!/usr/bin/env perl
# Copyright (C) 2012 Rocky Bernstein <rocky@cpan.org>
# Standalone routine to invoke a Perl program under the debugger.
# Modified though for being invoked from a front-end Bullwinkle
# protocol, so errors should go back there.

# The usual boilerplate...
use strict; use warnings; use English qw( -no_match_vars );

use File::Basename; use File::Spec;
use File::Temp qw(tempfile);

my $dirname = dirname(__FILE__);
my $file = File::Spec->rel2abs(__FILE__);
my $TREPAN_DIR = File::Spec->catfile(dirname($file), '..', 'lib');

eval <<'EOE';
    use lib $TREPAN_DIR;
    use Devel::Trepan::Options;
    use Data::Dumper;
EOE
# FIXME: replace "die" with something else.
die $EVAL_ERROR if $EVAL_ERROR;

my $opts = Devel::Trepan::Options::process_options(\@ARGV);

my @exec_strs = @{$opts->{exec_strs}};
my @exec_strs_with_e = map {('-e', qq{'$_'})} @exec_strs;
my $cmd;
if (scalar @exec_strs) {
    $cmd = "$EXECUTABLE_NAME -c " . join(' ', @exec_strs_with_e) . 
        join(' ', @ARGV) . " 2>&1";
    @exec_strs_with_e = map {('-e', qq{$_})} @exec_strs;
} else {
    die "You need a Perl program to run or pass an string to eval" 
        unless @ARGV;

    # Resolve program name if it is not readable
    $ARGV[0] = whence_file($ARGV[0]) unless -r $ARGV[0];
    # Check that the debugged Perl program is syntactically valid.
    $cmd = "$EXECUTABLE_NAME -c " . join(' ', @ARGV) . " 2>&1";
}
my $output = `$cmd`;
my $rc = $? >>8;

# FIXME: Replace "print" and "exit" with something else
print "$output\n" if $rc;
exit $rc if $rc;

$opts->{dollar_0} = $ARGV[0];
$opts->{bw} = 1; # Unconditionally set to run Bullwinkle
$ENV{'TREPANPL_OPTS'} = Data::Dumper::Dumper($opts);
# print Dumper($opts), "\n";

# And just when you thought we'd never get around to actually 
# doing something...

my @ARGS = ($EXECUTABLE_NAME, '-I', $TREPAN_DIR, '-d:Trepan', 
            @exec_strs_with_e, @ARGV);
#print Dumper(\@ARGS), "\n";
if ($OSNAME eq 'MSWin32') {
    # I don't understand why but Strawberry Perl has trouble with exec.
    system @ARGS;
    exit $?;
} else {
    exec { $ARGS[0]} @ARGS;
}
