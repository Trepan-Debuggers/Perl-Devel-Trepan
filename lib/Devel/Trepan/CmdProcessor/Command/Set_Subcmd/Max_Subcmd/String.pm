# -*- coding: utf-8 -*-
# Copyright (C) 2011-2013 Rocky Bernstein <rocky@cpan.org>
use warnings; no warnings 'redefine'; no warnings 'once';

package Devel::Trepan::CmdProcessor::Command::Set::Max::String;

BEGIN {
    my @OLD_INC = @INC;
    use rlib '../../../../../..';
    use Devel::Trepan::CmdProcessor::Command::Subcmd::Subsubcmd;
    @INC = @OLD_INC
};

use strict;
use vars qw(@ISA @SUBCMD_VARS);
@ISA = qw(Devel::Trepan::CmdProcessor::Command::Subsubcmd);
# Values inherited from parent

use vars @Devel::Trepan::CmdProcessor::Command::Subsubcmd::SUBCMD_VARS;

our $IN_LIST      = 1;
our $HELP         = <<'HELP';
=pod

B<Set max st>[B<ring>] I<number>

Sometimes the string representation of an object is very long. This
setting limits how much of the string representation you want to
see. However if the string has an embedded newline then we will assume
the output is intended to be formated as is.
=cut
HELP

our $MIN_ABBREV   = length('str');
our $SHORT_HELP   = "Set maximum chars in a string before truncation";

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
  # cmd_ary       = Trepan::SubSubcommand::SetMaxString::PREFIX
  # cmd_name      = cmd_ary.join(' ')
  # subcmd        = Trepan::SubSubcommand::SetMaxStringa.new(set_cmd.proc,
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
