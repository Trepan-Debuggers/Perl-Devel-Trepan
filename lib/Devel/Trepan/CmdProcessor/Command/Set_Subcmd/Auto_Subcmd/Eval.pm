# -*- coding: utf-8 -*-
# Copyright (C) 2011-2013 Rocky Bernstein <rocky@cpan.org>
use warnings; no warnings 'redefine'; no warnings 'once';

package Devel::Trepan::CmdProcessor::Command::Set::Auto::Eval;

BEGIN {
    my @OLD_INC = @INC;
    use rlib '../../../../../..';
    use Devel::Trepan::CmdProcessor::Command::Subcmd::Subsubcmd;
    @INC = @OLD_INC
};

use strict;
use vars qw(@ISA @SUBCMD_VARS);
@ISA = qw(Devel::Trepan::CmdProcessor::Command::SetBoolSubsubcmd);
# Values inherited from parent

use vars @Devel::Trepan::CmdProcessor::Command::Subsubcmd::SUBCMD_VARS;

our $IN_LIST      = 1;
our $HELP         = <<'HELP';
=pod

=pod

B<set auto <eval> [B<on>|B<off>]

Evaluate unrecognized debugger commands.

Often inside the debugger, one would like to be able to run arbitrary
Perl commands without having to preface expressions with C<print> or
C<eval>. Setting C<auto eval> on will cause unrecognized debugger
commands to be evaluated as a Perl expression.

If the expression starts with %, @, or $ the context will be set
to a hash, array or scalar accordingly.

Note that if auto eval is set, the message shown on type a bad
debugger command changes from:

  Undefined command: "fdafds". Try "help".

to something more Perl-specific such as:

  Unquoted string "fdasfdsa" may clash with future reserved word

One other thing that trips people up is when setting auto eval is that
there are some short debugger commands that sometimes one wants to use
as a variable, such as in an assignment statement. For example:

  s /a/b/  # Note the space after the s

is not a Perl substitute command but a "step" command when 'auto eval'
is on because by default, C<s> is an alias for the debugger C<step>
command. It is possible to remove that alias if this causes constant
problem. Another possibility is to go into a real shell via the
C<shell> command.
=cut
HELP

our $MIN_ABBREV   = length('ev');
use constant MAX_ARGS => 1;
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
