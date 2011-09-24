# -*- Coding: utf-8 -*-
# Copyright (C) 2011 Rocky Bernstein <rockb@cpan.org>
use warnings; no warnings 'redefine'; no warnings 'once';
use lib '../../../../..';

package Devel::Trepan::CmdProcessor::Command::Info::Breakpoints;
use Devel::Trepan::CmdProcessor::Command::Subcmd::Core;

use strict;
use vars qw(@ISA @SUBCMD_VARS);
@ISA = qw(Devel::Trepan::CmdProcessor::Command::Subcmd);
# Values inherited from parent
use vars @Devel::Trepan::CmdProcessor::Command::Subcmd::SUBCMD_VARS;

our $SHORT_HELP = 'List breakpoint information';

## FIXME: do automatically.
our $CMD = "info breakpoints";

our $HELP = <<"HELP";
${CMD} [num1 ...] [verbose]

Show status of user-settable breakpoints. If no breakpoint numbers are
given, the show all breakpoints. Otherwise only those breakpoints
listed are shown and the order given. If VERBOSE is given, more
information provided about each breakpoint.

The "Disp" column contains one of "keep", "del", the disposition of
the breakpoint after it gets hit.

The "enb" column indicates whether the breakpoint is enabled.

The "Where" column indicates where the breakpoint is located.
HELP

our $MIN_ABBREV  = length('br');
  
sub bpprint($$;$) 
{
    my ($self, $bp, $verbose) = @_;
    my $proc = $self->{proc};
    my $disp = ($bp->type eq 'tbreak') ? 'del  ' : 'keep ';
    $disp .= $bp->enabled ? 'y  '   : 'n  ';

    my $line_loc = sprintf('%s:%d', $bp->filename, $bp->line_num);

    if ($bp->condition && $bp->condition != '1') {
	my $msg = sprintf("\tstop %s %s", 
			  $bp->negate ? "unless" : "only if", 
			  $bp->condition);
	$proc->msg($msg);
    }
    if ($bp->ignore > 0) {
	my $msg = sprintf("\tignore next %d hits", $bp->ignore);
	$proc->msg($msg)
    }
    if ($bp->hits > 0) {
	my $ss = ($bp->hits > 1) ? 's' : '';
	my $msg = sprintf("\tbreakpoint already hit %d time%s",
			  $bp->hits, $ss);
	$proc->msg($msg);
    }
}

# sub save_command($)
# {
#     my $self = shift;
#     my $proc = $self->{proc};
#     my $bpmgr = $proc->{brkpts};
#     my @res = ();
#     for my $bp $bpmgr->list {
# 	# next unless 'file' == iseq.source_container[0]
# 	$loc = iseq.source_container[1] + ':';
# 	loc .=  iseq.offset2lines(bp.offset)[0].to_s;
# 	push @res, "break ${loc}";
#     }
# }

sub run($$) {
    my ($self, $args) = @_;
    my $verbose = 0;
    my $proc = $self->{proc};
    unless (scalar @$args) {
	if ('verbose' eq $args->[-1]) {
	    $verbose = 1;
	    pop @{$args};
	}
    }

    my $show_all = 1;
    if (scalar @{$args} > 2) {
	my @args = @{$args};
	pop @args; pop @args;
	my $max = $proc->{brkpts}->max;
        my $opts = {
	    msg_on_error => 
		"An '${CMD}' argument must eval to a breakpoint between 1..${max}.",
		min_value => 1,
		max_value => $max
	};
        my $bp_nums = $proc->get_int_list(@args);
	$show_all = 0;
    }
    
    my $bpmgr = $proc->{brkpts}->{list};
    if (0 == scalar @$bpmgr) {
	$proc->msg('No breakpoints.');
    } else {
	$proc->msg("Not finished yet...");
	return;

# 	# There's at least one
# 	$proc->section("Num Type          Disp Enb Where");
# 	if ($show_all) {
# 	    for my $bp ($bpmgr->list) {
# 		$self->bpprint($bp, $verbose);
# 	    }
# 	} else  {
# 	    my @notfound = ();
# 	    for my $bp_num ($bp_nums->list)  {
# 		my $bp = $proc->brkpts->list->[$bp_num];
# 		if ($bp) {
# 		    $self->bpprint($bp, $verbose);
# 		} else {
# 		    push @notfound, $bp_num;
# 		}
# 	    }
# 	    $proc->errmsg("No breakpoint number(s) ${not_found.join(' ')}.") unless scalar @notfound;
# 	}
#     }
#     if (0 == scalar @{$proc->traced_vars}) {
# 	$proc->msg('No traced variables.');
#     } else {
# 	$proc->section('Traced Variables');
# 	$proc->msg(columnize_commands(@proc.traced_vars.keys.sort));
    }
}

if (caller) {
  # Demo it.
  # require_relative '../../mock'
  # name = File.basename(__FILE__, '.rb')
  # dbgr, cmd = MockDebugger::setup('info')
  # subcommand = Trepan::Subcommand::InfoBreakpoints.new(cmd)

  # print '-' * 20
  # subcommand.run(%w(info break))
  # print '-' * 20
  # subcommand.summary_help(name)
  # print
  # print '-' * 20

  # require 'thread_frame'
  # tf = RubyVM::ThreadFrame.current
  # pc_offset = tf.pc_offset
  # sub foo
  #   5 
  # end
  
  # brk_cmd = dbgr.core.processor.commands['break']
  # brk_cmd.run(['break', "O${pc_offset}"])
  # cmd.run(%w(info break))
  # print '-' * 20
  # brk_cmd.run(['break', 'foo'])
  # subcommand.run(%w(info break))
  # print '-' * 20
  # print subcommand.save_command
}

1;
