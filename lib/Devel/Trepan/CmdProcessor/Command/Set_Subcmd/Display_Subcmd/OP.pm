# -*- coding: utf-8 -*-
# Copyright (C) 2012 Rocky Bernstein <rocky@cpan.org>
use warnings; no warnings 'redefine'; no warnings 'once';
use rlib '../../../../../..';

use Devel::Trepan::DB;

package Devel::Trepan::CmdProcessor::Command::Set::Display::OP;
use Devel::Trepan::CmdProcessor::Command::Subcmd::Subsubcmd;

use strict;
use vars qw(@ISA @SUBCMD_VARS);
@ISA = qw(Devel::Trepan::CmdProcessor::Command::SetBoolSubsubcmd);
# Values inherited from parent

use vars @Devel::Trepan::CmdProcessor::Command::Subsubcmd::SUBCMD_VARS;

our $IN_LIST      = 1;
our $HELP         = <<'HELP';
=pod

Set to show the OP address in location status.

The OP address is the address of the Perl Tree Opcode that is about
to be run. It gives the most precise indication of where you are.
This can be useful in disambiguating where among Perl several
statements in a line you are at. 

In the future we may also allow a breakpoint at a COP address.

See also L<C<show display
op>|Devel::Trepan::CmdProcessor::Command::Show::Display::OP>, C<show
line>, L<C<show
program>|Devel::Trepan::CmdProcessor::Command::Show::Program> and
C<disassemble> (via plugin L<Devel::Trepan::Disassemble>).
=cut
HELP

our $MIN_ABBREV   = length('co');
use constant MAX_ARGS => 1;
our $SHORT_HELP   = "Set to show OP address in locations";
 
sub run($$)
{ 
    my ($self, $args) = @_;
    if ($DB::HAVE_DEVEL_CALLSITE) {
        $self->SUPER::run($args);
    } else {
        $self->{proc}->errmsg("You need Devel::Callsite installed to run this");
    }
}

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
