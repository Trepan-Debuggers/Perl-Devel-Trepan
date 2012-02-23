# Copyright (C) 2011 Rocky Bernstein <rocky@cpan.org>
# -*- coding: utf-8 -*-
use warnings; no warnings 'redefine';
use rlib '../../../..';

# disable breakpoint command. The difference however is that the
# parameter to @proc.en_disable_breakpoint_by_number is different (set
# as ENABLE_PARM below).
#
# NOTE: The enable command  subclasses this, so beware when changing! 
package Devel::Trepan::CmdProcessor::Command::Enable;
use if !@ISA, Devel::Trepan::CmdProcessor::Command ;
unless (@ISA) {
    eval <<"EOE";
use constant CATEGORY => 'breakpoints';
use constant SHORT_HELP => 'Enable some breakpoints';
use constant MIN_ARGS  => 0;  # Need at least this many
use constant MAX_ARGS  => undef;  # Need at most this many - undef -> unlimited.
EOE
}

use strict;
use vars qw(@ISA);

@ISA = @CMD_ISA;
use vars @CMD_VARS;  # Value inherited from parent

# require_relative '../breakpoint'
# require_relative '../../app/util'

our $NAME = set_name();
our $HELP = <<"HELP";
${NAME} NUM [NUM ...]
    
Enables breakpoints, watch expressions or actions given as a space
separated list of numbers which may be prefaces with an 'a', 'b', or 'w'.
The prefaces are interpreted as follows:
  a:  action number
  b:  breakpoint number
  w:  watch expression number

If NUM is starts with a digit NUM is taken to be a breakpoint number.

Examples:

   $NAME 1 2    # Enable breakpoint 1 and 2
   $NAME b1 b2  # Same as above
   $NAME a4     # Enable action 4
   $NAME w1 2   # Enable watch expression 1 and breakpoint 2

See also "info break" to get a list of breakpoints, and "disable" to
disable breakpoints.
HELP

### FIXME: parameterize and combine these. Also combine with disable.
sub enable_breakpoint($$) {
    my ($proc, $i) = @_;
    my $bp = $proc->{brkpts}->find($i);
    my $msg;
    if ($bp) {
	if ($bp->enabled) {
	    $msg = sprintf("Breakpoint %d already enabled", $bp->id);
	    $proc->errmsg($msg);
	} else {
	    $bp->enabled(1);
	    $msg = sprintf("Breakpoint %d enabled", $bp->id);
	    $proc->msg($msg);
	}
    } else {
	$msg = sprintf("No breakpoint %d found", $i);
	$proc->errmsg($msg);
    }
}
    
sub enable_watchpoint($$) {
    my ($proc, $i) = @_;
    my $wp = $proc->{dbgr}{watch}->find($i);
    my $msg;
    if ($wp) {
	if ($wp->enabled) {
	    $msg = sprintf("Watch expression %d already enabled", $wp->id);
	    $proc->errmsg($msg);
	} else {
	    $wp->enabled(1);
	    $msg = sprintf("Watch expression %d enabled", $wp->id);
	    $proc->msg($msg);
	}
    } else {
	$msg = sprintf("No watchpoint %d found", $i);
	$proc->errmsg($msg);
    }
}
    
sub enable_action($$) {
    my ($proc, $i) = @_;
    my $act = $proc->{actions}->find($i);
    my $msg;
    if ($act) {
	if ($act->enabled) {
	    $msg = sprintf("Action %d already enabled", $act->id);
	    $proc->errmsg($msg);
	} else {
	    $act->enabled(1);
	    $msg = sprintf("Action %d enabled", $act->id);
	    $proc->msg($msg);
	}
    } else {
	$msg = sprintf("No action %d found", $i);
	$proc->errmsg($msg);
    }
}
    
sub run($$)
{
    my ($self, $args) = @_;
    my $proc = $self->{proc};
    my @args = @{$args};
    if (scalar @args == 1) {
	$proc->errmsg('No breakpoint number given.');
	return;
    }
    my $first = shift @args;
    for my $num_str (@args) {
	my $type = lc(substr($num_str,0,1));
	if ($type !~ /[0-9baw]/) {
	    $proc->errmsg("Invalid prefix $type. Argument $num_str ignored");
	    next;
	}
	if ($type =~ /[0-9]/) {
	    $type='b';
	} else {
	    $num_str = substr($num_str, 1);
	}
	my $i = $proc->get_an_int($num_str);
	if (defined $i) {
	    if ('a' eq $type) {
		disable_action($proc, $i); 
	    } elsif ('b' eq $type) {
		disable_breakpoint($proc, $i); 
	    } elsif ('w' eq $type) {
		disable_watchpoint($proc, $i);
	    }
	}
    }
}
        
unless (caller) {
  # require_relative '../mock'
  # dbgr, cmd = MockDebugger::setup
  # cmd.run([cmd.name])
  # cmd.run([cmd.name, '1'])
  # cmdproc = dbgr.core.processor
  # cmds = cmdproc.commands
  # break_cmd = cmds['break']
  # break_cmd.run(['break', cmdproc.frame.source_location[0].to_s])
  # # require_relative '../../lib/trepanning'
  # # Trepan.debug
  # cmd.run([cmd.name, '1'])
}

1;
