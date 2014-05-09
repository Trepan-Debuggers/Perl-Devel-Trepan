# -*- coding: utf-8 -*-
# Copyright (C) 2011, 2014 Rocky Bernstein <rocky@cpan.org>
use warnings; no warnings 'redefine'; no warnings 'once';
use rlib '../../../../..';

package Devel::Trepan::CmdProcessor::Command::Show::Timer;

use Devel::Trepan::CmdProcessor::Command::Subcmd::Core;

@ISA = qw(Devel::Trepan::CmdProcessor::Command::ShowBoolSubcmd);
# Values inherited from parent
use vars @Devel::Trepan::CmdProcessor::Command::Subcmd::SUBCMD_VARS;
# =pod
#
# =head2 Synopsis:
#
# =cut
our $HELP = <<"EOH";
=pod

B<show timer>

Show status of the timing hook.

=head2 See also:

L<C<set timer>|Devel::Trepan::CmdProcessor::Command::Set::Timer>
=cut
EOH
our $SHORT_HELP = "Show status of the timing hook";
our $MIN_ABBREV = length('ti');

unless (caller) {
  # Demo it.
  # require_relative '../../mock'

  # # FIXME: DRY the below code
  # my ($dbgr, $cmd) = MockDebugger::setup('show');
  # $subcommand = __PACKAGE__->new(cmd);
  # my $testcmdMgr = Trepan::Subcmd.new(subcommand);

  # $subcommand->run_show_bool();
  # $subcommand->summary_help($NAME);
}

1;
