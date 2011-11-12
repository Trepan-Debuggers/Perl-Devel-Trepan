# -*- coding: utf-8 -*-
# Copyright (C) 2011 Rocky Bernstein <rocky@cpan.org>
use warnings; no warnings 'redefine';

use rlib '../../../..';

# require_relative '../../app/condition'

package Devel::Trepan::CmdProcessor::Command::TBreak;

use if !defined @ISA, Devel::Trepan::CmdProcessor::Command ;
use strict;
use vars qw(@ISA); @ISA = @CMD_ISA;
use vars @CMD_VARS;  # Value inherited from parent

local $NAME = set_name();
local $HELP = <<"HELP";
${NAME} [LOCATION]

Set a one-time breakpoint. The breakpoint is removed after it is hit.
If no location is given use the current stopping point.

Examples:
   ${NAME}
   ${NAME} 10               # set breakpoint on line 10

See also "break".
HELP

use constant CATEGORY => 'breakpoints';
use constant SHORT_HELP => 'Set a one-time breakpoint';
$NEED_RUNNING = 1;


#  include Trepan::Condition

# This method runs the command
sub run($$) {
    my ($self, $args) = @_;
    $self->{dbgr}->set_tbreak($DB::filename, $args->[1]);
}

if (__FILE__ eq $0) {
  # require_relative '../mock'
  # dbgr, cmd = MockDebugger::setup
  # p cmd.run([cmd.name])
}

1;
