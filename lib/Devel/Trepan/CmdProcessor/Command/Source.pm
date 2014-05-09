# -*- coding: utf-8 -*-
# Copyright (C) 2011-2012, 2014 Rocky Bernstein <rocky@cpan.org>
use warnings; no warnings 'redefine';

use rlib '../../../..';

# Our local modules
## use Devel::Trepan::Options; or is it default
use Devel::Trepan::Interface::Script;
use Devel::Trepan::IO::NullOutput;

# Must be outside of package!
use if !@ISA, Devel::Trepan::Complete ;

package Devel::Trepan::CmdProcessor::Command::Source;
use Cwd 'abs_path';
use Getopt::Long qw(GetOptionsFromArray);
use if !@ISA, Devel::Trepan::CmdProcessor::Command ;

unless (@ISA) {
    eval <<'EOE';
use constant CATEGORY   => 'support';
use constant SHORT_HELP => 'Run debugger commands from a file';
use constant MIN_ARGS   => 1;     # Need at least this many
use constant MAX_ARGS   => undef; # Need at most this many - undef -> unlimited.
use constant NEED_STACK => 0;
EOE
}

use strict;

use vars qw(@ISA); @ISA = qw(Devel::Trepan::CmdProcessor::Command);
use vars @CMD_VARS;  # Value inherited from parent

our $NAME = set_name();
=pod

=head2 Synopsis:

=cut
our $HELP = <<'HELP';
=pod

B<source> [I<options>] I<file>

options:

    -q | --quiet | --no-quiet
    -c | --continue | --no-continue
    -Y | --yes | -N | --no
    -v | --verbose | --no-verbose

Read debugger commands from a file named I<file>.  Optional C<-v> switch
causes each command in FILE to be echoed as it is executed.  Option C<-Y>
sets the default value in any confirmation command to be 'yes' and C<-N>
sets the default value to 'no'.

Option C<-q> will turn off any debugger output that normally occurs in
the running of the program.

An error in any command terminates execution of the command file
unless option C<-c> or C<--continue> is given.
=cut
HELP

# FIXME: put back in help.
# Note that the command startup file ${Devel::Trepan::CMD_INITFILE_BASE} is read automatically
# via a ${NAME} command the debugger is started.

my $DEFAULT_OPTIONS = {
    abort_on_error => 0,
    confirm_val => 0,
    quiet => 0,
    verbose => 0
};

sub complete($$) {
    my ($self, $prefix) = @_;
    my @files = Devel::Trepan::Complete::filename_list($prefix);
    my @opts = (qw(-c --continue --no --yes
              --verbose --no-verbose), @files);
    Devel::Trepan::Complete::complete_token(\@opts, $prefix) ;
}

sub parse_options($$)
{
    my ($self, $args) = @_;
    my $seen_yes_no = 0;
    my %opts = %$DEFAULT_OPTIONS;
    my $result = &GetOptionsFromArray($args,
          '--continue' => \$opts{cont},
          '--verbose'  => \$opts{verbose},
          '--no'       => \$opts{no},
          '--yes'      => sub { $opts{no} = 0; }
        );
    \%opts;
}

sub run($$)
{
    my ($self, $args) = @_;
    my @args = @$args;
    @args = splice @args, 1, scalar(@args) - 2;
    my $options = parse_options($self, \@args);
    my $intf = $self->{proc}{interfaces};
    my $output  = $options->{quiet} ? Devel::Trepan::IO::OutputNull->new :
        $intf->[-1]{output};

    my $filename = $args->[-1];

    my $expanded_filename = abs_path(glob($filename));
    unless (defined $expanded_filename && -f $expanded_filename) {
        my $mess = sprintf("Debugger command file '%s' is not found", $filename);
        $self->errmsg($mess);
        return 0;
    }
    unless(-r $expanded_filename) {
        my $mess = sprintf("Debugger command file '%s' (%s) is not a readable file", $filename, $expanded_filename);
        $self->errmsg($mess);
        return 0;
    }

    # Push a new debugger interface.
    my $script_intf = Devel::Trepan::Interface::Script->new($expanded_filename,
                                                            $output, $options);
    push @{$intf}, $script_intf;
}


# Demo it
unless (caller) {
  # require_relative '../mock'
  # dbgr, cmd = MockDebugger::setup
  # %w(--quiet -q --no-quiet --continue --no-continue -c -v --verbose
  #    --no-verbose).each do |opt|
  #   puts "parsing ${opt}"
  #   options =
  #     cmd.parse_options(Trepan::Command::SourceCommand::DEFAULT_OPTIONS.dup,
  #                       opt)
  #   p options
  # }

  # if ARGV.size >= 1
  #   puts "running... ${cmd.name} ${ARGV}"
  #   cmd.run([cmd.name, *ARGV])
  # }
}

1;
