# Copyright (C) 2011 Rocky Bernstein <rocky@cpan.org>
use strict;
use warnings;
package Devel::Trepan::Options;
use Getopt::Long qw(GetOptionsFromArray);
use File::Spec;
use lib '../..';

use vars qw(@EXPORT @ISA);
@EXPORT = qw( process_options whence_file);
@ISA    = qw(Exporter);

use constant DEFAULT_OPTIONS => {
    initial_dir  => undef, # If --cd option was given, we save it here.
    nx           => 0,     # Don't run user startup file (e.g. .trepanplrc)

    # Default values used only when 'server' or 'client'
    # (out-of-process debugging)
    port         => 1954,
    host         => 'localhost', 
    readline     => 1,  # Try to use GNU Readline?

};

use constant VERSION => '0.10';

sub show_version()
{
    printf "Trepan, version %s\n", VERSION;
    exit 10;
}

sub process_options($)
{
    $Getopt::Long::autoabbrev = 1;
    my ($argv) = @_;
    my ($show_version, $help);
    my $opts = DEFAULT_OPTIONS;

    my $result = &GetOptionsFromArray($argv,
	 'help'        => \$help,
	 'port:n'      => \$opts->{port},
	 'host:s'      => \$opts->{host},
	 'cd:s'        => \$opts->{initial_dir},
	 'nx'          => \$opts->{nx},
	 'readline'    => \$opts->{readline},
	 'version'     => \$show_version,
	);
    
    show_version() if $show_version;
    chdir $opts->{initial_dir} || die "Can't chdir to $opts->{initial_dir}" if
	defined($opts->{initial_dir});
    $opts;
}

# Do a shell-like path lookup for prog_script and return the results.
# If we can't find anything return the string given.
sub whence_file($)
{
    my $prog_script = shift;

    # If we have an relative or absolute file name, don't do anything.
    my $first_char = substr($prog_script, 0, 1);
    return $prog_script if index('./', $first_char) != -1;

    for my $dirname (File::Spec->path()) {
	my $prog_script_try = File::Spec->catfile($dirname, $prog_script);
	return $prog_script_try if -r $prog_script_try;
    }
    # Failure
    return $prog_script;
}

unless (caller) {
    my $argv = \@ARGV;
    my $opts = process_options($argv);
    printf "whence file for perl: %s\n", whence_file('perl');
    require Data::Dumper;
    import Data::Dumper;
    print Dumper($opts), "\n";
    my $pid = fork();
    if ($pid == 0) {
	my @argv = qw(--version);
	my $opts = process_options(\@argv);
	exit 0;
    } else {
	waitpid($pid, 0);
	print "exit code: ", $?>>8, "\n";
    }
    $pid = fork();
    if ($pid == 0) {
	my @argv = qw(--cd /tmp);
	my $opts = process_options(\@argv);
	exit 0;
    } else {
	waitpid($pid, 0);
	print "exit code: ", $?>>8, "\n";
    }
    $pid = fork();
    if ($pid == 0) {
	my @argv = qw(--cd /bogus);
	my $opts = process_options(\@argv);
	exit 0
    } else {
	waitpid($pid, 0);
	print "exit code: ", $?>>8, "\n";
    }
}

1;

