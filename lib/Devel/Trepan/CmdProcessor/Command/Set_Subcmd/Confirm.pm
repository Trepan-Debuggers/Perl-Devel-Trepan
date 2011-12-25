# -*- coding: utf-8 -*-
# Copyright (C) 2011 Rocky Bernstein <rocky@cpan.org>
use warnings; no warnings 'redefine'; no warnings 'once';
use rlib '../../../../..';

package Devel::Trepan::CmdProcessor::Command::Set::Confirm;

use Devel::Trepan::CmdProcessor::Command::Subcmd::Core;

our @ISA = (Devel::Trepan::CmdProcessor::Command::SetBoolSubcmd);
use strict;
# Values inherited from parent
use vars @Devel::Trepan::CmdProcessor::Command::Subcmd::SUBCMD_VARS;

## FIXME: do automatically.
our $CMD = "set confirm";
our $HELP   = <<"HELP";
${CMD} on|off

Set whether to confirm potentially dangerous operations.

Note some commands like 'quit' and 'kill' have a ! suffix which turns
the confirmation off in that specific instance.
HELP
our $SHORT_HELP = "Set whether to confirm potentially dangerous operations.";
our $MIN_ABBREV = length('con');

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
