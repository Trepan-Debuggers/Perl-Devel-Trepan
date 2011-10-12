# -*- coding: utf-8 -*-
# Copyright (C) 2011 Rocky Bernstein <rocky@cpan.org>
use warnings; no warnings 'redefine';

use lib '../../../..';

# require_relative '../running'
# require_relative '../../app/breakpoint' # FIXME: possibly temporary

package Devel::Trepan::CmdProcessor::Command::Continue;

use if !defined @ISA, Devel::Trepan::CmdProcessor::Command ;
use strict;
use vars qw(@ISA);
@ISA = @CMD_ISA;
use vars @CMD_VARS;  # Value inherited from parent

our $MIN_ARGS = 0;
our $MAX_ARGS = 2;
our $NAME = set_name();
our $HELP = <<"HELP";
${NAME} [LOCATION]

Leave the debugger loop and continue execution. Subsequent entry to
the debugger however may occur via breakpoints or explicit calls, or
exceptions.

If a parameter is given, a temporary breakpoint is set at that position
before continuing. 

Examples:
   ${NAME}
   ${NAME} 10    # continue to line 10
   ${NAME} gcd   # continue to first instruction of method gcd

See also 'step', 'next', 'finish', 'nexti' commands and "help location".
HELP

use constant ALIASES    => qw(c cont);
use constant CATEGORY   => 'running';
use constant SHORT_HELP => 'Continue running until end or brkpt';
local $NEED_RUNNING = 1;
local $MAX_ARGS     = 2;  # Need at most this many

# This method runs the command
sub run($$) {
    my ($self, $args) = @_;
    $self->{proc}->continue($args);
}

if (__FILE__ eq $0) {
  # require_relative '../mock'
  # dbgr, cmd = MockDebugger::setup
  # p cmd.run([cmd.name])
}

1;
