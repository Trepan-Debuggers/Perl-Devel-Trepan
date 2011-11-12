# -*- coding: utf-8 -*-
# Copyright (C) 2011 Rocky Bernstein <rocky@cpan.org>
use warnings; no warnings 'redefine'; no warnings 'once';
use rlib '../../../../..';

package Devel::Trepan::CmdProcessor::Command::Set::Different;

use Devel::Trepan::CmdProcessor::Command::Subcmd::Core;

@ISA = qw(Devel::Trepan::CmdProcessor::Command::SetBoolSubcmd);
# Values inherited from parent
use vars @Devel::Trepan::CmdProcessor::Command::Subcmd::SUBCMD_VARS;

our $HELP = "set different [on|off|nostack]

Set to make sure 'next' or 'step' moves to a new position.

Each line often may contain many possible stopping points. In a
debugger it is sometimes desirable to continue but stop only when the
position next changes.

Setting 'different' to on will cause each 'step' or 'next' command to
stop at a different position.

Note though that the notion of different does take into account stack
nesting. 

See also 'step', 'next' which have suffixes '+' and '-' which
override this setting.";
our $MIN_ABBREV = length('dif');
our $SHORT_HELP = "Set to make sure 'next/step' move to a new position.";

if (__FILE__ eq $0) {
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
