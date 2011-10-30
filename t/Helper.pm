package Helper;

use warnings; 
use strict;

use String::Diff;
use File::Basename qw(dirname);
use File::Spec;

use English qw( -no_match_vars ) ;

require Test::More;

my $trepanpl = File::Spec->catfile(dirname(__FILE__), qw(.. bin trepanpl));
my $debug = $^W;

sub _slurp
{
    my ($filename) = @_;

    open my $in, '<', $filename
        or die "Cannot open '$filename' for slurping - $!";

    local $/;
    my $contents = <$in>;

    close($in);

    return $contents;
}

sub run_debugger($$;$$)
{
    my ($test_invoke, $cmdfile, $rightfile, $opts) = @_;

    $opts //= {};

    Test::More::note( "running $test_invoke with $cmdfile" );

    my $run_opts = $opts->{run_opts} || "--basename --nx --no-highlight";
    my $full_cmdfile = File::Spec->catfile(dirname(__FILE__), 'data', $cmdfile);
    my $ext_file = sub {
        my ($ext) = @_;

        my $new_fn = $full_cmdfile;

        $new_fn =~ s/\.cmd\z/.$ext/;

        return $new_fn;
    };

    $run_opts .= " --command $full_cmdfile" unless ($opts->{no_cmdfile});

    if (!defined($rightfile))
    {
        $rightfile = $ext_file->('right');
    }

    my $cmd = "$EXECUTABLE_NAME $trepanpl $run_opts $test_invoke";
    print $cmd, "\n" if $debug;

    my $output = `$cmd`;
    my $rc = $? >> 8;

    print $output if $debug;
    Test::More::is($rc, 0);

    my $right_string = _slurp($rightfile);

    if ($opts->{filter})
    {
        ($output, $right_string) = $opts->{filter}->($output, $right_string);
    }

    my $gotfile = $ext_file->('got');

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
