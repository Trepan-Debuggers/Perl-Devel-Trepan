use warnings; use strict;
require Test::More;
use File::Spec;
use File::Basename;
my $trepanpl = File::Spec->catfile(dirname(__FILE__), qw(.. bin trepan.pl));
my $debug = $^W;

package Helper;
use File::Basename qw(dirname); use File::Spec;
use English qw( -no_match_vars ) ;
use Config;


# Runs debugger in subshell. 0 is returned if everything went okay.
# nonzero if something went wrong.
sub run_debugger($$;$$)
{
    my ($test_invoke, $cmd_filename, $right_filename, $opts) = @_;
    $opts = {} unless defined $opts;
    $opts->{do_test} = 1 unless exists $opts->{do_test};
    Test::More::note( "running $test_invoke with $cmd_filename" );
    my $run_opts = $opts->{run_opts} || "--basename --nx --no-highlight";
    my $dirname = dirname(__FILE__);
    my $full_cmd_filename = File::Spec->catfile($dirname, 'data', 
						$cmd_filename);

    # rlib seems to flip out if it can't find trepan.pl
    my $bin_dir = File::Spec->catfile($dirname, '..', 'bin');
    $ENV{PATH} = $bin_dir . $Config{path_sep} . $ENV{PATH};

    my $ext_file = sub {
        my ($ext) = @_;
        my $new_fn = $full_cmd_filename;
        $new_fn =~ s/\.cmd\z/.$ext/;
        return $new_fn;
    };

    $run_opts .= " --testing $full_cmd_filename" unless ($opts->{no_cmdfile});
    $right_filename = $ext_file->('right') unless defined($right_filename);
    my $cmd = "$EXECUTABLE_NAME $trepanpl $run_opts $test_invoke";
    print $cmd, "\n"  if $debug;
    my $output = `$cmd`;
    print "$output\n" if $debug;
    my $rc = $? >> 8;
    if ($opts->{do_test}) {
	Test::More::is($rc, 0, 'Debugger command executed successfully');
    }
    return $rc if $rc;
    open(RIGHT_FH, "<$right_filename");
    undef $INPUT_RECORD_SEPARATOR;
    my $right_string = <RIGHT_FH>;
    ($output, $right_string) = $opts->{filter}->($output, $right_string) if $opts->{filter};
    my $got_filename;
    $got_filename = $ext_file->('got');
    # TODO : Perhaps make sure we optionally use eq_or_diff from 
    # Test::Differences here.
    my $equal_output = $right_string eq $output;
    Test::More::ok($right_string eq $output, 'Output comparison') 
	if $opts->{do_test};
    if ($equal_output) {
        unlink $got_filename;
	return 0;
    } else {
        open (GOT_FH, '>', $got_filename)
            or die "Cannot open '$got_filename' for writing - $OS_ERROR";
        print GOT_FH $output;
        close GOT_FH;
        Test::More::diag("Compare $got_filename with $right_filename:");
	my $output = `diff -u $right_filename $got_filename 2>&1`;
	my $rc = $? >> 8;
	# GNU diff returns 0 if files are equal, 1 if different and 2
	# if something went wrong. We also should take care of the
	# case where diff isn't installed. So although we expect a 1
	# for GNU diff, we'll also take accept 0, but any other return
	# code means some sort of failure.
	$output = `diff $right_filename $got_filename 2>&1` 
	     if ($rc > 1) || ($rc < 0) ;
        Test::More::diag($output);
	return 1;
    }
}

1;
