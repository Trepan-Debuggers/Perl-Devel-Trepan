# -*- coding: utf-8 -*-
# Copyright (C) 2011, 2014 Rocky Bernstein <rocky@cpan.org>
use warnings; no warnings 'redefine'; no warnings 'once';
use rlib '../../../../../..';

package Devel::Trepan::CmdProcessor::Command::Show::Max::Stack;

# require_relative '../../base/subsubcmd'
use Devel::Trepan::CmdProcessor::Command::Subcmd::Subsubcmd;

use strict;
use vars qw(@ISA @SUBCMD_VARS);
@ISA = qw(Devel::Trepan::CmdProcessor::Command::ShowIntSubsubcmd);
# Values inherited from parent

use vars @Devel::Trepan::CmdProcessor::Command::Subsubcmd::SUBCMD_VARS;

our $IN_LIST      = 1;
our $MIN_ABBREV   = length('wid');
=pod

=head2 Synopsis:

=cut
our $HELP   = <<"HELP";
=pod

B<show max stack>

Show the number of backtrace lines the debugger will show.

=head2 See also:

L<C<set max stack>|Devel::Trepan::CmdProcessor::Set::Max::Stack>

=cut
HELP

our $SHORT_HELP   = 'Show the number of backtrace lines the debugger will show';

unless (caller) {
  # Demo it.
  # require_relative '../../../mock'
  # name = File.basename(__FILE__, '.rb')

  # dbgr, show_cmd = MockDebugger::showup('show')
  # max_cmd       = Trepan::SubSubcommand::ShowMax.new(dbgr.core.processor,
  #                                                     show_cmd)
  # cmd_ary       = Trepan::SubSubcommand::ShowMaxStack::PREFIX
  # cmd_name      = cmd_ary.join(' ')
  # subcmd        = Trepan::SubSubcommand::ShowMaxStack.new(show_cmd.proc,
    #                                                       max_cmd,
    #                                                       cmd_name)
  # prefix_run = cmd_ary[1..-1]
  # subcmd.run(prefix_run)
  # subcmd.run(prefix_run + %w(0))
  # subcmd.run(prefix_run + %w(20))
  # name = File.basename(__FILE__, '.rb')
  # subcmd.summary_help(name)
  # puts
  # puts '-' * 20
  # puts subcmd.save_command
}

1;
