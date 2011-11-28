# -*- coding: utf-8 -*-
# Copyright (C) 2011 Rocky Bernstein <rocky@cpan.org>
use warnings; no warnings 'redefine';
use rlib '../../../..';

package Devel::Trepan::CmdProcessor::Command::Info;

use if !defined @ISA, Devel::Trepan::CmdProcessor::Command::Subcmd::SubMgr;
use if !defined @ISA, Devel::Trepan::CmdProcessor::Command;
unless (defined(@ISA)) {
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
our $HELP = <<"HELP";
Generic command for showing things about the program being debugged. 

You can give unique prefix of the name of a subcommand to get
information about just that subcommand.

Type "${NAME}" for a list of "info" subcommands and what they do.
Type "help ${NAME} *" for just a list of "info" subcommands.
HELP

unless (caller) {
    require Devel::Trepan::CmdProcessor;
    my $proc = Devel::Trepan::CmdProcessor->new(undef, 'bogus');
    my $cmd = Devel::Trepan::CmdProcessor::Command::Show->new($proc, $NAME);
    # require_relative '../mock'
    # dbgr, cmd = MockDebugger::setup
    $cmd->run([$cmd->name])
}

1;
