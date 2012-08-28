# Copyright (C) 2011, 2012 Rocky Bernstein <rocky@cpan.org>
use strict;
use warnings;
package Devel::Trepan::Options;
use Getopt::Long qw(GetOptionsFromArray);
use Pod::Usage;
use Pod::Find qw(pod_where);
use File::Spec;
use rlib;

use vars qw(@EXPORT $DEFAULT_OPTIONS $PROGRAM_NAME $VERSION
            $HAVE_DATA_PRINT $HAVE_PERLTIDY);
@EXPORT = qw( process_options whence_file $DEFAULT_OPTIONS $PROGRAM_NAME 
              $HAVE_DATA_PRINT $HAVE_PERLTIDY
              $VERSION);
our @ISA;

BEGIN {
    $PROGRAM_NAME = 'trepan.pl';
    $VERSION      = '0.35';
}

use constant VERSION      => $VERSION;
use constant PROGRAM_NAME => $PROGRAM_NAME;

@ISA    = qw(Exporter);

# Return whether we want Terminal highlighting by default
sub default_term() {
    ($ENV{'TERM'} && ($ENV{'TERM'} ne 'dumb' || 
		     (exists($ENV{'EMACS'}) && $ENV{'EMACS'} eq 't')))
	?  'term' : 0
}

my $home = $ENV{'HOME'} || glob("~");
my $initfile = File::Spec->catfile($home, '.treplrc');
$DEFAULT_OPTIONS = {
    basename     => 0,
    batchfile    => undef,
    client       => 0,     # Set 1 if we want to connect to an out-of
                           # process debugger "server".
    cmddir       => [],    # Additional directories of debugger commands
    cmdfiles     => [],    # Files containing debugger commands to 'source'
    exec_strs    => [],    # Perl strings to evaluate
    fall_off_end => 0,     # Don't go into debugger on termination? 
    highlight    => default_term(),    
                           # Default values used only when 'server' or 'client'                            # (out-of-process debugging)
    host         => 'localhost', 
    initfile     => $initfile,
    initial_dir  => undef, # If --cd option was given, we save it here.
    nx           => 0,     # Don't run user startup file (e.g. .treplrc)
    port         => 1954,
    post_mortem  => 0,       # Go into debugger on die? 
    readline     => 1,       # Try to use GNU Readline?
    testing      => undef,
    traceprint   => 0,       # set -x tracing? 

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
	 'basename'     => \$opts->{basename},
	 'batch:s'      => \$opts->{batchfile},
	 'cd:s'         => \$opts->{initial_dir},
	 'client'       => \$opts->{client},
	 'cmddir=s@'    => \$opts->{cmddir},
	 'command=s@'   => \$opts->{cmdfiles},
	 'e|exec=s@'    => \$opts->{exec_strs},
	 'fall-off-end' => \$opts->{fall_off_end},
	 'help'         => \$help,
	 'highlight'    => \$opts->{highlight},
	 'host:s'       => \$opts->{host},
	 'man'          => \$man,
	 'no-highlight' => sub { $opts->{highlight} = 0},
	 'no-readline' => sub { $opts->{readline} = 0},
	 'nx'           => \$opts->{nx},
	 'port:n'       => \$opts->{port},
	 'post-mortem'  => \$opts->{post_mortem},
	 'readline'     => \$opts->{readline},
	 'server'       => \$opts->{server},
	 'testing:s'    => \$opts->{testing},
	 'version'      => \$show_version,
	 'x|trace'      => \$opts->{traceprint},
	);
    
    pod2usage(-input => pod_where({-inc => 1}, __PACKAGE__), 
	      -exitstatus => 1) if $help;
    pod2usage(-exitstatus => 10, -verbose => 2,
	      -input => pod_where({-inc => 1}, __PACKAGE__)) if $man;
    show_version() if $show_version;
    chdir $opts->{initial_dir} || die "Can't chdir to $opts->{initial_dir}" if
	defined($opts->{initial_dir});
    my $batch_filename = $opts->{testing};
    $batch_filename = $opts->{batchfile} unless defined $batch_filename;
    if ($batch_filename) {
	if (scalar(@{$opts->{cmdfiles}}) != 0) {
	    printf(STDERR "--batch option disables command files: %s\n", 
		   join(', ', @{$opts->{cmdfiles}}));
	    $opts->{cmdfiles} = [];
	}
	$opts->{nx} = 1;
    }
    if ($opts->{server} and $opts->{client}) {
	printf STDERR 
	    "Pick only on from of the --server or --client options\n";
    }
    $opts;
}

# Do a shell-like path lookup for prog_script and return the results.
# If we can't find anything return the string given.
sub whence_file($)
{
    my $prog_script = shift;

    # If we have an relative or absolute file name, don't do anything.
    return $prog_script if 
	File::Spec->file_name_is_absolute($prog_script);
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
	my @argv = qw(--cd /tmp --cmddir /tmp);
	my $opts = process_options(\@argv);
	print Dumper($opts), "\n";
	exit 0;
    } else {
	waitpid($pid, 0);
	print "exit code: ", $?>>8, "\n";
    }
    exit;
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

trepan.pl - Perl "Trepanning" Debugger 

=head1 SYNOPSIS

   trepan.pl [options] [[--] perl-program [perl-program-options ...]]

   Options:
      --help               brief help message
      --man                full documentation
      --basename           Show basename only on source file listings. 
                           (Needed in regression tests)
      
      -c| --command FILE   Run or 'source' debugger command file FILE
      --cmddir DIR         Read DIR for additional debugger commands
      --batch FILE         Like --command, but quit after reading FILE.
                           This option has precidence over --command and
                           will also set --nx
      --cd DIR             Change current directory to DIR
      -e| --exec STRING    eval STRING. Multiple -e's can be given.
                           Works like Perl's -e switch
      --nx                 Don't run user startup file (e.g. .treplrc)

      --client | --server  Set for out-of-process debugging. The server 
                           rus the Perl program to be debugged runs. 
                           The client runs outside of this process.
                          
      --fall-off-end       Don't stay in debugger when program terminates

      --host NAME          Set DNS name or IP address to communicate on.
                           The default is 127.0.0.1

      --port N             TCP/IP port to use on remote connection
                           The default is 1954
      --post-mortem        Enter debugger on die
      --readline  | --no-readline
                           Try or don't try to use Term::Readline
      -x|--trace           Simulate line tracing (think POSIX shell set -x)
      --highlight | --no-highlight 
                           Use or don't use ANSI terminal sequences for syntax
                           highlight

=head1 DESCRIPTION

B<trepan.pl> is a gdb-like debugger. Much of the interface and code has
been adapted from the trepanning debuggers of Ruby.

=cut
