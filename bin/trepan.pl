#!/usr/bin/env perl
# Copyright (C) 2012 Rocky Bernstein <rocky@cpan.org>
# Standalone routine to invoke a Perl program under the debugger.

# The usual boilerplate...
use strict; use warnings; use English qw( -no_match_vars );

use File::Basename; use File::Spec;
use File::Temp qw(tempfile);

my $dirname = dirname(__FILE__);
my $file = File::Spec->rel2abs(__FILE__);
my $TREPAN_DIR = File::Spec->catfile(dirname($file), '..', 'lib');

eval <<'EOE';
    use Data::Dumper;
    my @OLD_INC = @INC;
    use lib $TREPAN_DIR;
    use Devel::Trepan::Options;
    use Devel::Trepan::Client;
    use Devel::Trepan::Util;
    @INC = @OLD_INC;
EOE
die $EVAL_ERROR if $EVAL_ERROR;

my $opts = Devel::Trepan::Options::process_options(\@ARGV);

if ($opts->{client}) {
    Devel::Trepan::Client::start_client($opts);
    exit;
}

my @exec_strs = @{$opts->{exec_strs}};
my @exec_strs_with_e = map {('-e', qq{'$_'})} @exec_strs;
my $cmd;
if (scalar @exec_strs) {
    $cmd = join(' ', @exec_strs_with_e) . join(' ', @ARGV);
} else {
    die "You need a Perl program to run or pass an string to eval"
        unless @ARGV;

    # Resolve program name if it is not readable
    $ARGV[0] = whence_file($ARGV[0]) unless -r $ARGV[0];
    $cmd = join(' ', @ARGV);
}

# Check that the debugged Perl program is syntactically valid.
my $syntax_errmsg = Devel::Trepan::Util::invalid_perl_syntax($cmd, 1);
if ($syntax_errmsg) {
    print STDERR "$syntax_errmsg\n";
    exit -1;
}

$opts->{dollar_0} = $ARGV[0];
$ENV{'TREPANPL_OPTS'} = Data::Dumper::Dumper($opts);
# print Dumper($opts), "\n";

# And just when you thought we'd never get around to actually
# doing something...
my $i=0;
foreach my $arg (@exec_strs_with_e) {
    if ('-e' eq $arg && scalar(@exec_strs_with_e) > $i) {
	$exec_strs_with_e[$i+1] =~ s/^(["'])(.+)\1$/$2/ ;
	$i++;
    }
}

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
