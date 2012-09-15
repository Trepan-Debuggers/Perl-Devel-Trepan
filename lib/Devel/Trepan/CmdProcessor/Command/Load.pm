# -*- coding: utf-8 -*-
# Copyright (C) 2011-2012 Rocky Bernstein <rocky@cpan.org>
use warnings; no warnings 'redefine';
use rlib '../../../..';

package Devel::Trepan::CmdProcessor::Command::Load;

use if !@ISA, Devel::Trepan::CmdProcessor::Command::Subcmd::SubMgr;
use if !@ISA, Devel::Trepan::CmdProcessor::Command;
unless (@ISA) {
    eval <<'EOE';
use constant SHORT_HELP => 'Load or something Perlish'; 
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
our $HELP = <<'HELP';
=pod

Generic command for loading or reloading.

You can give unique prefix of the name of a subcommand to get
information about just that subcommand.

Type C<help load *> for a just list of C<load> subcommands.

Type C<load> for a list of subcommands and what they do.

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
