# -*- coding: utf-8 -*-
# Copyright (C) 2011 Rocky Bernstein <rocky@cpan.org>
use warnings; no warnings 'redefine'; no warnings 'once';
use rlib '../../../../../..';

package Devel::Trepan::CmdProcessor::Command::Set::Max::Width;
use Devel::Trepan::CmdProcessor::Command::Subcmd::Subsubcmd;

use strict;
use vars qw(@ISA @SUBCMD_VARS);
@ISA = qw(Devel::Trepan::CmdProcessor::Command::Subsubcmd);
# Values inherited from parent

use vars @Devel::Trepan::CmdProcessor::Command::Subsubcmd::SUBCMD_VARS;

our $HELP = 'Set max width NUMBER

Set number of characters the debugger thinks are in a line.';
our $IN_LIST      = 1;
our $MIN_ABBREV   = length('wid');

sub run($$)
{
    my ($self, $args) = @_;
    my @args = @$args;
    shift @args; shift @args; shift @args;
    my $num_str = join(' ', @args);
    $self->run_set_int($num_str, 
		       "The '$self->{cmd_str}' command requires a line width", 
		       0);
}

unless (caller) {
  # Demo it.
  # require_relative '../../../mock'
  # name = File.basename(__FILE__, '.rb')

  # dbgr, set_cmd = MockDebugger::setup('set')
  # max_cmd       = Trepan::SubSubcommand::SetMax.new(dbgr.core.processor, 
  #                                                     set_cmd)
  # cmd_ary       = Trepan::SubSubcommand::SetMaxWidth::PREFIX
  # cmd_name      = cmd_ary.join(' ')
  # subcmd        = Trepan::SubSubcommand::SetMaxWidth.new(set_cmd.proc,
  #                                                        max_cmd,
  #                                                        cmd_name)
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
