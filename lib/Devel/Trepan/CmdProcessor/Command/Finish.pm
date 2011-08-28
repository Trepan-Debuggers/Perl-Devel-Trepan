# -*- coding: utf-8 -*-
# Copyright (C) 2011 Rocky Bernstein <rocky@cpan.org>
use warnings; no warnings 'redefine';

use lib '../../../../..';

# require_relative '../running'
# require_relative '../../app/breakpoint' # FIXME: possibly temporary

package Devel::Trepan::CmdProcessor::Command::Finish;

use if !defined @ISA, Devel::Trepan::CmdProcessor::Command ;
use strict;
use vars qw(@ISA);
@ISA = @CMD_ISA;
use vars @CMD_VARS;  # Value inherited from parent

our $NAME = set_name();
our $HELP = <<"HELP";
${NAME} [LEVELS]

Continue execution until the program is about to leaving the current
function or switch context via yielding or ending a block which was
yield to. Sometimes this is called 'step out'.

When LEVELS is specified, that many frame levels need to be
popped. The default is 1.  Note that 'yield' and exceptions raised my
reduce the number of stack frames. Also, if a thread is switched, we
stop ignoring levels.

See the break command if you want to stop at a particular point in a
program. In general, '${NAME}', 'step' and 'next' may slow a program down
while 'break' will have less overhead.

HELP

use constant ALIASES    => qw(fin);
use constant CATEGORY   => 'running';
use constant SHORT_HELP => 'Step to end of current method (step out)';
local $NEED_RUNNING = 1;
local $MAX_ARGS     = 1;  # Need at most this many

# This method runs the command
sub run($$) {
    my ($self, $args) = @_;
    
    my $count = scalar @$args > 1 ? $args->[1] : 1;
    $self->{proc}->{leave_cmd_loop} = 1;
    $self->{dbgr}->finish($count);
}

unless (caller) {
  # require_relative '../mock'
  # dbgr, cmd = MockDebugger::setup
  # p cmd.run([cmd.name])
}

1;
