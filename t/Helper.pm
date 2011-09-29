use warnings; use strict;
use String::Diff;
my $trepanpl = File::Spec->catfile(dirname(__FILE__), qw(.. bin trepanpl));
my $debug = $^W;

package Helper;
use File::Basename qw(dirname); use File::Spec;
use English;
require Test::More;
sub run_debugger($$;$)
{
    my ($test_invoke, $cmdfile, $rightfile) = @_;
    Test::More::note( "running $test_invoke with $cmdfile" );
    my $full_cmdfile = File::Spec->catfile(dirname(__FILE__), 'data', $cmdfile);
    ($rightfile = $full_cmdfile) =~ s/\.cmd/.right/ unless defined($rightfile);
    my $opts = "--basename --nx --no-highlight --command $full_cmdfile";
    my $cmd = "$EXECUTABLE_NAME $trepanpl $opts $test_invoke";
    print $cmd, "\n" if $debug;
    my $output = `$cmd`;
    print $output if $debug;
    my $rc = $? >> 8;
    Test::More::is($rc, 0);
    open(RIGHT_FH, "<$rightfile");
    undef $INPUT_RECORD_SEPARATOR;
    my $right_string = <RIGHT_FH>;
    if ($right_string eq $output) {
	Test::More::ok(1);
    } else {
	my $diff = String::Diff::diff_merge($output, $right_string);
	my $gotfile;
	($gotfile = $full_cmdfile) =~ s/\.cmd/.got/;
	open(GOT_FH, ">$gotfile");
	print GOT_FH $output;
	print $diff;
	Test::More::ok(0, "Output comparison fails");
    }
}

1;
