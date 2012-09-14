# -*- Coding: utf-8 -*-
# Copyright (C) 2011-2012 Rocky Bernstein <rocky@cpan.org>
use warnings; no warnings 'redefine'; no warnings 'once';
use rlib '../../../../..';

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

our $HELP = <<'HELP';
=pod

info breakpoints [I<num1> ...] [verbose]

Show status of user-settable breakpoints. If no breakpoint numbers are
given, the show all breakpoints. Otherwise only those breakpoints
listed are shown and the order given. If VERBOSE is given, more
information provided about each breakpoint.

The C<Disp> column contains one of C<keep>, C<del>, the disposition of
the breakpoint after it gets hit.

The C<Enb> column indicates whether the breakpoint is enabled.

The C<Where> column indicates where the breakpoint is located.
=cut
HELP

our $MIN_ABBREV  = length('br');
  
sub complete($$)
{
    my ($self, $prefix) = @_;
    my @completions = $self->{proc}{brkpts}->ids;
    Devel::Trepan::Complete::complete_token(\@completions, $prefix);
}

sub bpprint($$;$) 
{
    my ($self, $bp, $verbose) = @_;
    my $proc = $self->{proc};
    my $disp = ($bp->type eq 'tbreak') ? 'del  ' : 'keep ';
    $disp .= $bp->enabled ? 'y  '   : 'n  ';

    my $line_loc = sprintf('%s:%d', $proc->canonic_file($bp->filename), 
                           $bp->line_num);

    my $mess = sprintf('%-4dbreakpoint    %s at %s',
                       $bp->id, $disp, $line_loc);
    $proc->msg($mess);

    if ($bp->condition && $bp->condition ne '1') {
        my $msg = sprintf("\tstop %s %s", 
                          $bp->negate ? "unless" : "only if", 
                          $bp->condition);
        $proc->msg($msg);
    }
    if ($bp->hits > 0) {
        my $ss = ($bp->hits > 1) ? 's' : '';
        my $msg = sprintf("\tbreakpoint already hit %d time%s",
                          $bp->hits, $ss);
        $proc->msg($msg);
    }
}

sub action_print($$;$) 
{
    my ($self, $action, $verbose) = @_;
    my $proc = $self->{proc};
    my $disp = $action->enabled ? 'y  '   : 'n  ';

    my $line_loc = sprintf('%s:%d', $action->filename, $action->line_num);

    my $mess = sprintf('%-4daction     %s at %s',
                       $action->id, $disp, $line_loc);
    $proc->msg($mess);

    if ($action->condition && $action->condition ne '1') {
        my $msg = sprintf("\texpression: %s", $action->condition);
        $proc->msg($msg);
    }
    if ($action->hits > 0) {
        my $ss = ($action->hits > 1) ? 's' : '';
        my $msg = sprintf("\taction already hit %d time%s",
                          $action->hits, $ss);
        $proc->msg($msg);
    }
}


# sub save_command($)
# {
#     my $self = shift;
#     my $proc = $self->{proc};
#     my $bpmgr = $proc->{brkpts};
#     my @res = ();
#     for my $bp ($bpmgr->list) {
#       push @res, "break ${loc}";
#     }
#    return @res;
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
    my $show_actions = 1;
    my $show_watch = 1;
    my @args = ();
    if (scalar @{$args} > 2) {
        @args = splice(@{$args}, 2);
        my $max = $proc->{brkpts}->max;
        my $opts = {
            msg_on_error => 
                "An '${CMD}' argument must eval to a breakpoint between 1..${max}.",
                min_value => 1,
                max_value => $max
        };
        @args = $proc->get_int_list(\@args);
        $show_all = $show_watch = $show_actions = 0;
    }

    my $bpmgr = $proc->{brkpts};
    $bpmgr->compact;
    my @brkpts = @{$bpmgr->{list}};
    if (0 == scalar @brkpts) {
        $proc->msg('No breakpoints.');
    } else {
        # There's at least one
        $proc->section("Num Type          Disp Enb Where");
        if ($show_all) {
            for my $bp (@brkpts) {
                $self->bpprint($bp, $verbose);
            }
        } else  {
            my @not_found = ();
            for my $bp_num (@args)  {
                next unless $bp_num;
                my $bp = $bpmgr->find($bp_num);
                if ($bp) {
                    $self->bpprint($bp, $verbose);
                } else {
                    push @not_found, $bp_num;
                }
            }
            if (scalar @not_found) {
                my $msg = sprintf("No breakpoint number(s) %s.\n",
                                  join(', ', @not_found));
                $proc->errmsg($msg);
            }
        }
    }

    if ($show_actions) {
        my $actmgr = $proc->{actions};
        $actmgr->compact;
        my @actions = @{$actmgr->{list}};
        if (0 == scalar @actions) {
            $proc->msg('No actions.');
        } else {
            # There's at least one
            $proc->section("Num Type       Enb Where");
            if ($show_all) {
                for my $action (@actions) {
                    $self->action_print($action, $verbose);
                }
            } else  {
                my @not_found = ();
                for my $action_num (@args)  {
                    my $action = $actmgr->find($action_num);
                    if ($action) {
                    $self->actino_print($action, $verbose);
                    } else {
                        push @not_found, $action_num;
                    }
                }
                unless (scalar @not_found) {
                    my $msg = sprintf("No action number(s) %s.\n",
                                      join(', ', @not_found));
                    $proc->errmsg($msg);
                }
            }
        }
    }
    if ($show_watch) {
        $self->{proc}->run_command('info watch');
    }
}

if (caller) {
  # Demo it.
  # use rlib '../../mock'
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
