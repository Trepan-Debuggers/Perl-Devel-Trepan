# -*- coding: utf-8 -*-
# Copyright (C) 2011, 2014 Rocky Bernstein <rocky@cpan.org>
use warnings; no warnings 'redefine'; no warnings 'once';
use rlib '../../../../..';

package Devel::Trepan::CmdProcessor::Command::Set::Different;

use Devel::Trepan::CmdProcessor::Command::Subcmd::Core;

@ISA = qw(Devel::Trepan::CmdProcessor::Command::SetBoolSubcmd);
# Values inherited from parent
use vars @Devel::Trepan::CmdProcessor::Command::Subcmd::SUBCMD_VARS;

=pod

=head2 Synopsis:

=cut
our $HELP = <<'HELP';
=pod

B<set different> [B<on>|B<off>|B<nostack>]

Set to make sure C<next> or C<step> moves to a new position.  If "on",
"off", or "nostack" is not given, "on" is assumed.

A line can contain many possible stopping points. Inside a debugger,
it is sometimes desirable to continue but stop only when the position
next changes.

Setting C<different> to on will cause each C<step> or C<next> command to
stop at a different position.

Note though that the notion of different does take into account stack
nesting.

=head2 See also:

L<C<step>|Devel::Trepan::CmdProcessor::Command::step>, and
L<C<next>|Devel::Trepan::CmdProcessor::Command::Next> which have
suffixes C<+> and C<->; the suffixes override this setting.

=cut
HELP

sub complete($$)
{
    my ($self, $prefix) = @_;
    Devel::Trepan::Complete::complete_token(['on', 'off', 'nostack'],
					    $prefix);
}


our $MIN_ABBREV = length('dif');
our $SHORT_HELP = "Set to make sure 'next/step' move to a new position.";

unless (caller) {
  # Demo it.
  # require_relative '../../mock'

  # # FIXME: DRY the below code
  # my $cmd =
  #   Devel::Trepan::MockDebugger::sub_setup(__PACKAGE__, 0);
  # $cmd->run(@$cmd->prefix + ('off'));
  # $cmd->run(@$cmd->prefix + ('ofn'));
  # $cmd->run(@$cmd->prefix);
  # print $cmd->save_command(), "\n";

}

1;
