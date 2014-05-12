# -*- coding: utf-8 -*-
# Copyright (C) 2011-2012, 2014 Rocky Bernstein <rocky@cpan.org>
use warnings; no warnings 'redefine';
use rlib '../../../..';

package Devel::Trepan::CmdProcessor::Command::Load;

use if !@ISA, Devel::Trepan::CmdProcessor::Command::Subcmd::SubMgr;
use if !@ISA, Devel::Trepan::CmdProcessor::Command;
unless (@ISA) {
    eval <<'EOE';
use constant ALIASES    => qw(reload);
use constant CATEGORY   => 'support';
use constant MAX_ARGS   => undef; # Need at most this many - undef -> unlimited.
use constant MIN_ARGS   => 0;     # Need at least this many
use constant NEED_STACK => 0;
use constant SHORT_HELP => 'Load or reload something Perlish';
EOE
}

use strict;
use vars qw(@ISA);
@ISA = qw(Devel::Trepan::CmdProcessor::Command::SubcmdMgr);
use vars @CMD_VARS;

$NAME = set_name();
=pod

=head2 Synopsis:

=cut
our $HELP = <<"HELP";
=pod

B<load> [I<load sub-commmand> ...]

Generic command for loading or reloading.

You can give unique prefix of the name of a subcommand to get
information about just that subcommand.

Type C<help load *> for a just list of C<load> subcommands.

Type C<load> for a list of subcommands and what they do.

=head2 See also:

L<C<load subcmd>|Devel::Trepan::CmdProcessor::Command::Load::Subcmd>,
L<C<load command>|Devel::Trepan::CmdProcessor::Command::Load::Command>,
L<C<load module>|Devel::Trepan::CmdProcessor::Command::Load::module>, and
L<C<load source>|Devel::Trepan::CmdProcessor::Command::Load::Source>.

=cut
HELP

unless (caller) {
    require Devel::Trepan::CmdProcessor;
    my $proc = Devel::Trepan::CmdProcessor->new(undef, 'bogus');
    my $cmd = Devel::Trepan::CmdProcessor::Command::Show->new($proc, $NAME);
    # require_relative '../mock'
    # dbgr, cmd = MockDebugger::setup
    $cmd->run([$NAME])
}

1;
