# Copyright (C) 2011 Rocky Bernstein <rocky@cpan.org>
# -*- coding: utf-8 -*-
use warnings; no warnings 'redefine';
use rlib '../../../..';

# disable breakpoint command. The difference however is that the
# parameter to @proc.en_disable_breakpoint_by_number is different (set
# as ENABLE_PARM below).
#
# NOTE: The enable command  subclasses this, so beware when changing! 
package Devel::Trepan::CmdProcessor::Command::Disable;
use if !@ISA, Devel::Trepan::CmdProcessor::Command ;
use strict;

use vars qw(@ISA);

unless (@ISA) {
    eval <<"EOE";
use constant CATEGORY   => 'breakpoints';
use constant SHORT_HELP => 'Disable some breakpoints';
use constant MIN_ARGS  => 0;  # Need at least this many
use constant MAX_ARGS  => undef;  # Need at most this many - undef -> unlimited.
use constant NEED_STACK => 0;
EOE
}

@ISA = @CMD_ISA;
use vars @CMD_VARS;  # Value inherited from parent

# require_relative '../breakpoint'
# require_relative '../../app/util'

our $NAME = set_name();
our $HELP = <<"HELP";
${NAME} bpnumber [bpnumber ...]
    
Disables the breakpoints given as a space separated list of breakpoint
numbers. See also "info break" to get a list.
HELP
    
### FIXME: parameterize and combine these. Also combine with enable.
sub disable_breakpoint($$) {
    my ($proc, $i) = @_;
    my $bp = $proc->{brkpts}->find($i);
    my $msg;
    if ($bp) {
	if ($bp->enabled) {
	    $bp->enabled(0);
	    $msg = sprintf("Breakpoint %d disabled", $bp->id);
	    $proc->msg($msg);
	} else {
	    $msg = sprintf("Breakpoint %d already disabled", $bp->id);
	    $proc->errmsg($msg);
	}
    } else {
	$msg = sprintf("No breakpoint %d found", $i);
	$proc->errmsg($msg);
    }
}

sub disable_watchpoint($$) {
    my ($proc, $i) = @_;
    my $wp = $proc->{dbgr}{watch}->find($i);
    my $msg;
    if ($wp) {
	if ($wp->enabled) {
	    $wp->enabled(0);
	    $msg = sprintf("Watch expression %d disabled", $wp->id);
	    $proc->msg($msg);
	} else {
	    $msg = sprintf("Watch expression %d already disabled", $wp->id);
	    $proc->errmsg($msg);
	}
    } else {
	$msg = sprintf("No watchpoint %d found", $i);
	$proc->errmsg($msg);
    }
}
    
sub disable_action($$) {
    my ($proc, $i) = @_;
    my $act = $proc->{actions}->find($i);
    my $msg;
    if ($act) {
	if ($act->enabled) {
	    $act->enabled(0);
	    $msg = sprintf("Action %d disabled", $act->id);
	    $proc->msg($msg);
	} else {
	    $msg = sprintf("Action %d already disabled", $act->id);
	    $proc->errmsg($msg);
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
