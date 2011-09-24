# Copyright (C) 2011 Rocky Bernstein <rocky@cpan.org>
# -*- coding: utf-8 -*-
use warnings; no warnings 'redefine';
use lib '../../../..';

# disable breakpoint command. The difference however is that the
# parameter to @proc.en_disable_breakpoint_by_number is different (set
# as ENABLE_PARM below).
#
# NOTE: The enable command  subclasses this, so beware when changing! 
package Devel::Trepan::CmdProcessor::Command::Enable;
use if !defined @ISA, Devel::Trepan::CmdProcessor::Command ;
unless (defined @ISA) {
    eval "use constant CATEGORY => 'breakpoints'";
    eval "use constant SHORT_HELP => 'Enable some breakpoints'";
}

use strict;
use vars qw(@ISA);

@ISA = @CMD_ISA;
use vars @CMD_VARS;  # Value inherited from parent

# require_relative '../breakpoint'
# require_relative '../../app/util'

our $NAME = set_name();
our $HELP = <<"HELP";
#{NAME} [display] bpnumber [bpnumber ...]
    
Enables the breakpoints given as a space separated list of breakpoint
numbers. See also "info break" to get a list.
HELP
    
sub run($$)
{
    my ($self, $args) = @_;
    my $proc = $self->{proc};
    my @args = @{$args};
    if (scalar @args == 1) {
	$proc->errmsg('No breakpoint number given.');
	return;
    }
#   if args[1] == 'display'
#     display_enable(args[2:], 0)
#   end
    my $first = shift @args;
    for my $num_str (@args) {
	my $i = $proc->get_an_int($num_str);
	if (defined $i) {
	    my $bp = $proc->{brkpts}->find($i);
	    if ($bp) {
		my $msg;
		if ($bp->enabled) {
		    $msg = sprintf("Breakpoint %s already enabled", $bp->id);
		} else {
		    $bp->enabled(1);
		    $msg = sprintf("Breakpoint %s enabled", $bp->id);
		}
		$proc->msg($msg);
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
