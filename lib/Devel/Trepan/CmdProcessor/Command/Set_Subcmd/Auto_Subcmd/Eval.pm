# -*- coding: utf-8 -*-
# Copyright (C) 2011 Rocky Bernstein <rocky@cpan.org>
use warnings; no warnings 'redefine'; no warnings 'once';
use rlib '../../../../../..';

package Devel::Trepan::CmdProcessor::Command::Set::Auto::Eval;
use Devel::Trepan::CmdProcessor::Command::Subcmd::Subsubcmd;

use strict;
use vars qw(@ISA @SUBCMD_VARS);
@ISA = qw(Devel::Trepan::CmdProcessor::Command::SetBoolSubsubcmd);
# Values inherited from parent

use vars @Devel::Trepan::CmdProcessor::Command::Subsubcmd::SUBCMD_VARS;

our $IN_LIST      = 1;
our $HELP         = <<"HELP";

Evaluate unrecognized debugger commands.

Often inside the debugger, one would like to be able to run arbitrary
Ruby commands without having to preface Python expressions with \"print\" or
\"eval\". Setting \"auto eval\" on will cause unrecognized debugger
commands to be evaluated as a Perl expression. 

Note that if this is set, on error the message shown on type a bad
debugger command changes from:

  Undefined command: \"fdafds\". Try \"help\".

to something more Perl-specific such as:

  NameError: name 'fdafds' is not defined

One other thing that trips people up is when setting auto eval is that
there are some short debugger commands that sometimes one wants to use
as a variable, such as in an assignment statement. For example:

  \$s = 5

which produce when 'auto eval' is on:
  *** Command 'step' can take at most 1 argument(s); got 2.

because by default, 's' is an alias for the debugger 'step'
command. It is possible to remove that alias if this causes constant
problem. Another possibility is to go into a real Ruby shell via the
'irb' command.
HELP

our $MIN_ABBREV   = length('ev');
our $MAX_ARGS     = 1;
our $SHORT_HELP   = "Set evaluation of unrecognized debugger commands";
 
unless (caller) {
  # Demo it.
  # require_relative '../../../mock'
  # name = File.basename(__FILE__, '.rb')

  # dbgr, set_cmd = MockDebugger::setup('set')
  # $max_cmd       = __PACKAGE__->new(dbgr.core.processor, $set_cmd)
  # $cmd_ary       = Trepan::SubSubcommand::SetMaxList::PREFIX
  # $cmd_name      = cmd_ary.join(' ')
  # $subcmd        = __PACKAGE__->new($set_cmd->{proc}, $max_cmd, $cmd_name);
  # $prefix_run = cmd_ary[1..-1]
  # $subcmd->run(prefix_run);
  # $subcmd-.run(prefix_run, qw(0));
  # $subcmd->run(prefix_run, qw(20));
  # $subcmd->summary_help(name);
  # print
  # print '-' x 20;
  # print $subcmd->save_command
}

1;
