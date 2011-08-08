# -*- coding: utf-8 -*-
# Copyright (C) 2011 Rocky Bernstein <rocky@cpan.org>
use warnings; no warnings 'redefine'; no warnings 'once';
use lib '../../../../..';

package Devel::Trepan::CmdProcessor::Command::Show::Different;

use Devel::Trepan::CmdProcessor::Command::Subcmd::Core;

@ISA = qw(Devel::Trepan::CmdProcessor::Command::ShowBoolSubcmd);
# Values inherited from parent
use vars @Devel::Trepan::CmdProcessor::Command::Subcmd::SUBCMD_VARS;

our $HELP = "Show status of 'set different'";
our $MIN_ABBREV = length('dif');

if (__FILE__ eq $0) {
  # Demo it.
  # require_relative '../../mock'

  # # FIXME: DRY the below code
  # my ($dbgr, $cmd) = MockDebugger::setup('show');
  # $subcommand = __PACKAGE__->new(cmd);
  # $testcmdMgr = Trepan::Subcmd->new(subcommand);

  # $subcommand->run_show_bool();
  # $subcommand->summary_help($NAME);
}

1;
