# -*- coding: utf-8 -*-
# Copyright (C) 2011, 2014 Rocky Bernstein <rocky@cpan.org>
use warnings; no warnings 'redefine'; no warnings 'once';
use rlib '../../../../..';

package Devel::Trepan::CmdProcessor::Command::Show::Basename;
use Devel::Trepan::CmdProcessor::Command::Subcmd::Core;

@ISA = qw(Devel::Trepan::CmdProcessor::Command::ShowBoolSubcmd);
# Values inherited from parent
use vars @Devel::Trepan::CmdProcessor::Command::Subcmd::SUBCMD_VARS;

=pod

=head2 Synopsis:

=cut
our $HELP = <<"EOH";
=pod

B<show baseame>

Show whether file basename are used showing file names.

=head2 See also:

L<C<set basename>|Devel::Trepan::CmdProcessor::Command::Set::Basename>
=cut
EOH
our $SHORT_HELP = "Show whether file basename are used showing file names";
our $MIN_ABBREV = length('ba');

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
