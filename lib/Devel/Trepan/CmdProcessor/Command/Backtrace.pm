# Copyright (C) 2011 Rocky Bernstein <rocky@cpan.org>
use warnings; no warnings 'redefine';

use lib '../../../..';

package Devel::Trepan::CmdProcessor::Command::Backtrace;
use if !defined @ISA, Devel::Trepan::CmdProcessor::Command ;
use strict;

use vars qw(@ISA); @ISA = @CMD_ISA; 
use vars @CMD_VARS;  # Value inherited from parent

our $NAME = set_name();
our $HELP = <<"HELP";
${NAME} [count]

Print a stack trace, with the most recent frame at the top.  With a
positive number, print at most many entries.  With a negative number
print the top entries minus that number.

An arrow indicates the 'current frame'. The current frame determines
the context used for many debugger commands such as expression
evaluation or source-line listing.

Examples:
   ${NAME}    # Print a full stack trace
   ${NAME} 2  # Print only the top two entries
   ${NAME} -1 # Print a stack trace except the initial (least recent) call."
      HELP
HELP

use constant ALIASES    => qw(bt where);
use constant CATEGORY   => 'stack';
use constant SHORT_HELP => 'Print backtrace of stack frames';
our $MAX_ARGS     = 1;  # Need at most this many

# sub complete($$)
# { 
#     my ($self, $prefix) = @_;
#     $self->{proc}->frame_complete($prefix, undef);
# }
  
# This method runs the command
sub run($$)
{
    my ($self, $args) = @_;
    my @frames = $self->{dbgr}->backtrace(0);
    $self->{proc}->print_stack_trace(\@frames);
}

if (__FILE__ eq $0) {
    require Devel::Trepan::CmdProcessor;
    my $proc = Devel::Trepan::CmdProcessor->new(undef, 'bogus');
    my $cmd = Devel::Trepan::CmdProcessor::Command::Backtrace->new($proc);
    $cmd->run([$NAME]);
}

1;
