# -*- coding: utf-8 -*-
# Copyright (C) 2012 Rocky Bernstein <rocky@cpan.org>
use warnings; no warnings 'redefine'; no warnings 'once';
use rlib '../../../../../..';

package Devel::Trepan::CmdProcessor::Command::Show::Debug::Except;
use Devel::Trepan::CmdProcessor::Command::Subcmd::Subsubcmd;

use strict;
use vars qw(@ISA @SUBCMD_VARS);
@ISA = qw(Devel::Trepan::CmdProcessor::Command::ShowBoolSubsubcmd);
# Values inherited from parent

use vars @Devel::Trepan::CmdProcessor::Command::Subsubcmd::SUBCMD_VARS;

our $IN_LIST      = 1;
use constant MAX_ARGS => 0;
our $HELP         = "Show debugging debuger-handled exceptions";

our $MIN_ABBREV   = length('ex');
 
unless (caller) {
  # Demo it.
  # require_relative '../../../mock'

  # dbgr, set_cmd = MockDebugger::setup('set');
  # $max_cmd       = __PACKAGE__->new(dbgr.core.processor, $set_cmd);
  # $cmd_ary       = __PACKAGE__->{prefix};
  # $cmd_name      = cmd_ary.join(' ');
  # $subcmd        = __PACAKGE__->new(set_cmd.proc, max_cmd, cmd_name);
  # prefix_run = cmd_ary[1..-1]
  # $subcmd->run(prefix_run)
  # $subcmd->run(($prefix_run, qw(0)));
  # $subcmd->run(($prefix_run, qw(20)));
  # $subcmd->summary_help($name);
  # print
  # print '-' x 20;
  # print $subcmd->save_command
}

1;
