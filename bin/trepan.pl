#!/usr/bin/env perl
# Standalone routine to invoke a Perl program under the debugger.

# The usual boilerplate...
use strict; use warnings; use English qw( -no_match_vars );

use File::Basename; use File::Spec;
my $dirname = dirname(__FILE__);
my $file = File::Spec->rel2abs(__FILE__);
my $TREPAN_DIR = File::Spec->catfile(dirname($file), '..', 'lib');

eval <<'EOE';
    use lib $TREPAN_DIR;
    use Devel::Trepan::Options;
    use Devel::Trepan::Client;
    use Data::Dumper;
EOE
die $EVAL_ERROR if $EVAL_ERROR;

my $opts = Devel::Trepan::Options::process_options(\@ARGV);

if ($opts->{client}) {
    Devel::Trepan::Client::start_client({host=>$opts->{host}, 
					 port=>$opts->{port}});
    exit;
}

die "You need a Perl program to run" unless @ARGV;

# Resolve program name if it is not readable
$ARGV[0] = whence_file($ARGV[0]) unless -r $ARGV[0];

# Check that the debugged Perl program is syntactically valid.
my $cmd = "$EXECUTABLE_NAME -c " . join(' ', @ARGV) . " 2>&1";
my $output = `$cmd`;
my $rc = $? >>8;
print "$output\n" if $rc;
exit $rc if $rc;

$ENV{'TREPANPL_OPTS'} = Data::Dumper::Dumper($opts);
# print Dumper($opts), "\n";

# And just when you thought we'd never get around to actually 
# doing something...

my @ARGS = ($EXECUTABLE_NAME, '-I', $TREPAN_DIR, '-d:Trepan', @ARGV);
if ($OSNAME eq 'MSWin32') {
    # I don't understand why but Strawberry Perl has trouble with exec.
    system @ARGS;
    exit $?;
} else {
    exec { $ARGS[0]} @ARGS;
}
