# -*- coding: utf-8 -*-
# Copyright (C) 2011 Rocky Bernstein <rocky@cpan.org>
use warnings; no warnings 'redefine'; no warnings 'once';
use rlib '../../../../..';

package Devel::Trepan::CmdProcessor::Command::Set::Timer;

use Devel::Trepan::CmdProcessor::Command::Subcmd::Core;

@ISA = qw(Devel::Trepan::CmdProcessor::Command::SetBoolSubcmd);
# Values inherited from parent
use vars @Devel::Trepan::CmdProcessor::Command::Subcmd::SUBCMD_VARS;

our $IN_LIST      = 1;
our $HELP         = <<"HELP";
set timer [on|off]

Tracks and shows elapsed time between debugger events.

Since debugger overhead can be large depending on what you are doing,
there are many ways to customize the debugger to take less time (and
do less).

Stepping is slow, running to a breakpoint without stepping is
relatively fast compared to previous versions of the debugger and
compared to stepping. 

Stopping at fewer events can also speed things up. Trace event
buffering slows things down.

Buy turning this setting on, you may be able to get a feel for what
how expensive the various settings.

See also: 'set events', 'set trace buffer', 'step', and 'break'.
HELP

our $SHORT_HELP = "Set to show elapsed time between debugger events";
our $MIN_ABBREV = length('ti');

sub run($$)
{
    my ($self, $args) = @_;
    $self->SUPER::run($args);
    my $proc = $self->{proc};
    if ( $proc->{settings}{timer} ) {
	$proc->{cmdloop_posthooks}->insert_if_new(-1, $proc->{timer_hook}[0],
						  $proc->{timer_hook}[1]);
	$proc->{cmdloop_prehooks}->insert_if_new(-1, $proc->{timer_hook}[0],
						 $proc->{timer_hook}[1]);
    } else {
	$proc->{cmdloop_posthooks}->delete_by_name('timer');
	$proc->{cmdloop_posthooks}->delete_by_name('timer');
    }
}

unless (caller) {
  # Demo it.
  # require_relative '../../mock'

  # # FIXME: DRY the below code
  # my $cmd = 
  #   Devel::Trepan::MockDebugger::sub_setup(__PACKAGE__, 0);
  # $cmd->run(@$cmd->prefix + ('off'));
  # $cmd->run(@$cmd->prefix + ('ofn'));
  # $cmd->run(@$cmd->prefix);
  # print $cmd->save_command(), "\n";

}

1;
