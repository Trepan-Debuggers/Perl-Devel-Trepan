use warnings; use strict;
use String::Diff;
use File::Spec;
use File::Basename;
my $trepanpl = File::Spec->catfile(dirname(__FILE__), qw(.. bin trepanpl));
my $debug = $^W;

package Helper;
use File::Basename qw(dirname); use File::Spec;
use English;
require Test::More;
sub run_debugger($$;$$)
{
    my ($test_invoke, $cmdfile, $rightfile, $opts) = @_;
    $opts //= {};
    Test::More::note( "running $test_invoke with $cmdfile" );
    my $run_opts = $opts->{run_opts} || "--basename --nx --no-highlight";
    my $full_cmdfile = File::Spec->catfile(dirname(__FILE__), 'data', $cmdfile);
    $run_opts .= " --command $full_cmdfile" unless ($opts->{no_cmdfile});
    ($rightfile = $full_cmdfile) =~ s/\.cmd/.right/ unless defined($rightfile);
    my $cmd = "$EXECUTABLE_NAME $trepanpl $run_opts $test_invoke";
    print $cmd, "\n" if $debug;
    my $output = `$cmd`;
    print $output if $debug;
    my $rc = $? >> 8;
    Test::More::is($rc, 0);
    open(RIGHT_FH, "<$rightfile");
    undef $INPUT_RECORD_SEPARATOR;
    my $right_string = <RIGHT_FH>;
    ($output, $right_string) = $opts->{filter}->($output, $right_string) if $opts->{filter};
    my $gotfile;
    ($gotfile = $full_cmdfile) =~ s/\.cmd/.got/;
    if ($right_string eq $output) {
	Test::More::ok(1);
	unlink $gotfile;
    } else {
	my $diff = String::Diff::diff_merge($output, $right_string);
	open(GOT_FH, ">$gotfile");
	print GOT_FH $output;
	print $diff;
	Test::More::ok(0, "Output comparison fails");
    }
}

1;
