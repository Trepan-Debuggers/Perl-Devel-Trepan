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
    my ($test_invoke, $cmd_fn, $right_fn, $opts) = @_;

    $opts //= {};

    Test::More::note( "running $test_invoke with $cmd_fn" );

    my $run_opts = $opts->{run_opts} || "--basename --nx --no-highlight";
    my $full_cmd_fn = File::Spec->catfile(dirname(__FILE__), 'data', $cmd_fn);
    my $ext_filename = sub {
        my ($ext) = @_;

        my $new_fn = $full_cmd_fn;

        $new_fn =~ s/\.cmd\z/.$ext/;

        return $new_fn;
    };

    $run_opts .= " --command $full_cmd_fn" unless ($opts->{no_cmdfile});

    if (!defined($right_fn))
    {
        $right_fn = $ext_filename->('right');
    }

    my $cmd = "$EXECUTABLE_NAME $trepanpl $run_opts $test_invoke";
    print $cmd, "\n" if $debug;

    my $output = `$cmd`;
    my $rc = $? >> 8;

    print $output if $debug;
    Test::More::is($rc, 0);

    my $right_string = _slurp($right_fn);

    if ($opts->{filter})
    {
        ($output, $right_string) = $opts->{filter}->($output, $right_string);
    }

    my $got_fn = $ext_filename->('got');

    # TODO : Perhaps make sure we optionally use eq_or_diff from 
    # Test::Differences here.
    if (Test::More::is($right_string, $output, 'Output comparison')) {
        unlink $got_fn;
    } else {
        my $diff = String::Diff::diff_merge($output, $right_string);

        open (my $got_fh, '>', $got_fn)
            or die "Cannot open '$got_fn' for writing - $!";
        print {$got_fh} $output;
        close($got_fh);

        Test::More::diag($diff);
    }
}

1;
