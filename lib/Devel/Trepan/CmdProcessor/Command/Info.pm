# -*- coding: utf-8 -*-
# Copyright (C) 2011-2014 Rocky Bernstein <rocky@cpan.org>
use warnings; no warnings 'redefine';

package Devel::Trepan::CmdProcessor::Command::Info;
use rlib '../../../..';

use if !@ISA, Devel::Trepan::CmdProcessor::Command::Subcmd::SubMgr;
use if !@ISA, Devel::Trepan::CmdProcessor::Command;
unless (@ISA) {
    eval <<'EOE';
use constant SHORT_HELP => 'Information about debugged program and its environment';
use constant CATEGORY => 'status';
use constant MIN_ARGS   => 0;  # Need at least this many
use constant MAX_ARGS   => undef; # Need at most this many - undef -> unlimited.
use constant NEED_STACK => 0;
EOE
}

use strict;
use vars qw(@ISA);
@ISA = qw(Devel::Trepan::CmdProcessor::Command::SubcmdMgr);
use vars @CMD_VARS;

our $NAME       = set_name();
=pod

=head2 Synopsis:

=cut
our $HELP = <<'HELP';
=pod

B<info> [I<info sub-commmand> ...]

Generic command for showing things about the program being debugged.

You can give unique prefix of the name of a subcommand to get
information about just that subcommand.

Type C<info> for a list of subcommands and what they do.

Type C<help info *> for a list of C<info> subcommands.

=head2 See also:

L<C<info
breakpoints>|Devel::Trepan::CmdProcessor::Command::Info::Breakpoints>,
L<C<info files>|Devel::Trepan::CmdProcessor::Command::Info::Files>,
L<C<info frame>|Devel::Trepan::CmdProcessor::Command::Info::Frame>,
L<C<info functions>|Devel::Trepan::CmdProcessor::Command::Info::Functions>,
L<C<info line>|Devel::Trepan::CmdProcessor::Command::Info::Line>,
L<C<info macros>|Devel::Trepan::CmdProcessor::Command::Info::Macros>,
L<C<info program>|Devel::Trepan::CmdProcessor::Command::Info::Program>,
L<C<info return>|Devel::Trepan::CmdProcessor::Command::Info::Return>,
L<C<info signals>|Devel::Trepan::CmdProcessor::Command::Info::Signals>,
L<C<info variables>|Devel::Trepan::CmdProcessor::Command::Info::Variables>,
and
L<C<info watch>|Devel::Trepan::CmdProcessor::Command::Info::Watch>
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
