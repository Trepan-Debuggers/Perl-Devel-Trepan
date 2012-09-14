# -*- coding: utf-8 -*-
# Copyright (C) 2011-2012 Rocky Bernstein <rocky@cpan.org>
use warnings; no warnings 'redefine';
use rlib '../../../..';

package Devel::Trepan::CmdProcessor::Command::Show;

use if !@ISA, Devel::Trepan::CmdProcessor::Command::Subcmd::SubMgr;
use if !@ISA, Devel::Trepan::CmdProcessor::Command;

unless (@ISA) {
    eval <<'EOE';
use constant CATEGORY => 'status';
use constant SHORT_HELP => 'Show parts of the debugger environment';
use constant MIN_ARGS   => 0;     # Need at least this many
use constant MAX_ARGS   => undef; # Need at most this many - undef -> unlimited.
use constant NEED_STACK => 0;
EOE
}

use strict;
use vars qw(@ISA);
@ISA = qw(Devel::Trepan::CmdProcessor::Command::SubcmdMgr);
use vars @CMD_VARS;

$NAME = set_name();
$HELP = <<'HELP';
=pod 

Generic command for showing things about the debugger.  You can
give unique prefix of the name of a subcommand to get information
about just that subcommand.

Type C<show> for a list of show subcommands and what they do.
Type C<help show *> for a list of C<show> subcommands.
=cut
HELP

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

unless (caller) {
    require Devel::Trepan::CmdProcessor;
    my $proc = Devel::Trepan::CmdProcessor->new(undef, 'bogus');
    my $cmd = __PACKAGE__->new($proc, $NAME);
    # require_relative '../mock'
    # dbgr, cmd = MockDebugger::setup
    $cmd->run([$NAME])
}

1;
