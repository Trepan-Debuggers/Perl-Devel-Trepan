# -*- coding: utf-8 -*-
# Copyright (C) 2011, 2014 Rocky Bernstein <rocky@cpan.org>
use warnings; no warnings 'redefine'; no warnings 'once';
use rlib '../../../../..';

package Devel::Trepan::CmdProcessor::Command::Show::Confirm;

use Devel::Trepan::CmdProcessor::Command::Subcmd::Core;

@ISA = qw(Devel::Trepan::CmdProcessor::Command::ShowBoolSubcmd);
# Values inherited from parent
use vars @Devel::Trepan::CmdProcessor::Command::Subcmd::SUBCMD_VARS;

=pod

=head2 Synopsis:

=cut

our $HELP=<<"EOH";
=pod

B<show confirm>

Show whether to confirm potentially dangerous operations.

=head2 See also:

L<C<set confirm>|Devel::Trepan::CmdProcessor::Command::Set::Confirm>
=cut
EOH
our $SHORT_HELP = "Show whether to confirm potentially dangerous operations";
our $MIN_ABBREV = length('co');

unless (caller) {
  # Demo it.
  # require_relative '../../mock'

  # # FIXME: DRY the below code
  # dbgr, cmd = MockDebugger::setup('show')
  # subcommand = __PACKAGE__->new(cmd)
  # testcmdMgr = Trepan::Subcmd.new(subcommand)

  # subcommand.run_show_bool
  # name = File.confirm(__FILE__, '.rb')
  # subcommand.summary_help(name)
}

1;
