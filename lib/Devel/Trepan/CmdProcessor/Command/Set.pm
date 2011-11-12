# -*- coding: utf-8 -*-
# Copyright (C) 2011 Rocky Bernstein <rocky@cpan.org>
use warnings; no warnings 'redefine';
use rlib '../../../..';

package Devel::Trepan::CmdProcessor::Command::Set;

use if !defined @ISA, Devel::Trepan::CmdProcessor::Command::Subcmd::SubMgr;
use if !defined @ISA, Devel::Trepan::CmdProcessor::Command;
use strict;
use vars qw(@ISA);
@ISA = qw(Devel::Trepan::CmdProcessor::Command::SubcmdMgr);
use vars @CMD_VARS;

local $NAME = set_name();
our $HELP = <<"HELP";
Modifies parts of the debugger environment.

You can give unique prefix of the name of a subcommand to get
information about just that subcommand.

Type "${NAME}" for a list of "${NAME}" subcommands and what they do.
Type "help ${NAME} *" for just the list of "${NAME}" subcommands.

For compatability with older ruby-debug "${NAME} auto..." is the
same as "${NAME} auto ...". For example "${NAME} autolist" is the same 
as "${NAME} auto list".
HELP

use constant CATEGORY => 'support';
use constant SHORT_HELP => 'Modify parts of the debugger environment';
local $NEED_STACK     = 0;
$MAX_ARGS             = 1000;
$MIN_ARGS             = 0;

sub run($$) 
{
    my ($self, $args) = @_;
    my $first;
    if (scalar @$args > 1) {
	$first = lc $args->[1];
	my $alen = length('auto');
	splice(@$args, 1, 2, ('auto', substr($first, $alen))) if
	    index($first, 'auto') == 0 && length($first) > $alen;
    }
    $self->SUPER::run($args);
}

if (__FILE__ eq  $0) {
    require Devel::Trepan::CmdProcessor;
    my $proc = Devel::Trepan::CmdProcessor->new(undef, 'bogus');
    my $cmd = __PACKAGE__->new($proc, $NAME);
    # require_relative '../mock'
    # dbgr, cmd = MockDebugger::setup
    $cmd->run([$NAME]);
    # $cmd->run([$NAME, 'autolist']);
    # $cmd->run([$NAME, 'autoeval', 'off']);
    $cmd->run([$NAME, 'basename']);
}

1;
