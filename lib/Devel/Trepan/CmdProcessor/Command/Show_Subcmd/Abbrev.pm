# -*- coding: utf-8 -*-
# Copyright (C) 2011, 2012 Rocky Bernstein <rocky@cpan.org>
use warnings; no warnings 'redefine'; no warnings 'once';
use rlib '../../../../..';

package Devel::Trepan::CmdProcessor::Command::Show::Abbrev;

use Devel::Trepan::CmdProcessor::Command::Subcmd::Core;

@ISA = qw(Devel::Trepan::CmdProcessor::Command::ShowBoolSubcmd);
# Values inherited from parent
use vars @Devel::Trepan::CmdProcessor::Command::Subcmd::SUBCMD_VARS;

our $HELP = "Show whether we allow abbreviated debugger command names";
our $MIN_ABBREV = length('ab');

unless (caller) {
  # Demo it.
  # require_relative '../../mock'

  # # FIXME: DRY the below code
  # my ($dbgr, $cmd) = MockDebugger::setup('show');
  # $subcommand = __PACKAGE__->new($cmd);
  # $testcmdMgr = Trepan::Subcmd->new($subcommand);

  # $subcommand->run_show_bool();
  # $subcommand->summary_help($NAME);
}

1;
