# Copyright (C) 2011 Rocky Bernstein <rocky@cpan.org>
use strict;
use warnings;
package Devel::Trepan::Options;
use Getopt::Long qw(GetOptionsFromArray);
use Pod::Usage;
use Pod::Find qw(pod_where);
use File::Spec;
use rlib '../..';

use vars qw(@EXPORT @ISA $DEFAULT_OPTIONS $PROGRAM_NAME $VERSION);
@EXPORT = qw( process_options whence_file $DEFAULT_OPTIONS $PROGRAM_NAME $VERSION);

BEGIN {
    $PROGRAM_NAME = 'trepanpl';
    $VERSION      = '0.1.1';
}
use constant VERSION => $VERSION;
use constant PROGRAM_NAME => $PROGRAM_NAME;

@ISA    = qw(Exporter);

my $home = $ENV{'HOME'} || glob("~");
my $initfile = File::Spec->catfile($home, '.treplrc');
$DEFAULT_OPTIONS = {
    initial_dir  => undef, # If --cd option was given, we save it here.
    initfile     => $initfile,
    batchfile    => undef,
    testing      => undef,
    basename     => 0,
    nx           => 0,     # Don't run user startup file (e.g. .treplrc)
    cmdfiles     => [],
    highlight    => 1,
    # Default values used only when 'server' or 'client'
    # (out-of-process debugging)
    port         => 1954,
    host         => 'localhost', 
    traceprint   => 0,       # set -x tracing? 
    readline     => 1,       # Try to use GNU Readline?

};


sub show_version()
{
    printf "Trepan, version %s\n", VERSION;
    exit 10;
}

sub process_options($)
{
    $Getopt::Long::autoabbrev = 1;
    my ($argv) = @_;
    my ($show_version, $help, $man);
    my $opts = $DEFAULT_OPTIONS;

    my $result = &GetOptionsFromArray($argv,
	 'help'         => \$help,
	 'man'          => \$man,
	 'port:n'       => \$opts->{port},
	 'highlight'    => \$opts->{highlight},
	 'no-highlight' => sub { $opts->{highlight} = 0},
	 'host:s'       => \$opts->{host},
	 'basename'     => \$opts->{basename},
	 'batch:s'      => \$opts->{batchfile},
	 'testing:s'    => \$opts->{testing},
	 'c|command=s@' => \$opts->{cmdfiles},
	 'cd:s'         => \$opts->{initial_dir},
	 'nx'           => \$opts->{nx},
	 'readline'     => \$opts->{readline},
	 'x|trace'      => \$opts->{traceprint},
	 'version'      => \$show_version,
	);
    
    pod2usage(-input => pod_where({-inc => 1}, __PACKAGE__), 
	      -exitstatus => 1) if $help;
    pod2usage(-exitstatus => 10, -verbose => 2,
	      -input => pod_where({-inc => 1}, __PACKAGE__)) if $man;
    show_version() if $show_version;
    chdir $opts->{initial_dir} || die "Can't chdir to $opts->{initial_dir}" if
	defined($opts->{initial_dir});
    my $batch_filename = $opts->{testing} // $opts->{batchfile};
    if ($batch_filename) {
	if (scalar(@{$opts->{cmdfiles}}) != 0) {
	    print STDERR "--batch option disables any command files";
	    $opts->{cmdfiles} = [];
	}
	$opts->{nx} = 1;
    }
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
    $pid = fork();
    if ($pid == 0) {
	my @argv = ('--batch', __FILE__);
	my $opts = process_options(\@argv);
	print Dumper($opts), "\n";
	exit 0
    } else {
	waitpid($pid, 0);
	print "exit code: ", $?>>8, "\n";
    }
}

1;

__END__
    
=head1 TrepanPl

trepanpl - Perl "Trepanning" Debugger 

=head1 SYNOPSIS

   trepan [options] [[--] perl-program [perl-program-options ...]]

   Options:
      --help              brief help message
      --man               full documentation
      --basename          Show basename only on source file listings. 
                          (Needed in regression tests)
      -c| --command FILE  Run debugger command file FILE
      --batch FILE        Like --command, but quit after reading FILE.
                          This option has precidence over --command and
                          will also set --mx
      --cd DIR            Change current directory to DIR
      --nx                Don't run user startup file (e.g. .treplrc)
      --port N            TCP/IP port to use on remote connection
      --readline          Try to use Term::Readline
      -x|--trace          Simulate line tracing (think POSIX shell set -x)
      --highlight | --no-highlight 
                          Use or don't use ANSI terminal sequences for syntax
                          highlight

=head1 DESCRIPTION

B<trepanpl> is a gdb-like debugger. Much of the interface and code has
been adapted from the trepanning debuggers of Ruby.

=cut
