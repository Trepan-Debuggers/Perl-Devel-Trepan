# -*- coding: utf-8 -*-
# Copyright (C) 2011, 2014-2015 Rocky Bernstein <rocky@cpan.org>
use warnings; no warnings 'redefine'; no warnings 'once';
use rlib '../../../../..';
use strict;
use vars qw(@ISA @SUBCMD_VARS);

package Devel::Trepan::CmdProcessor::Command::Set::Trace;

use Devel::Trepan::CmdProcessor::Command::Subcmd::Core;
use Devel::Trepan::CmdProcessor::Command::Subcmd::SubsubMgr;
use vars qw(@ISA @SUBCMD_VARS);
our $MIN_ABBREV = length('tr');
=pod

=head2 Synopsis:

=cut
our $HELP   = <<"HELP";
=pod

B<set trace> [I<set trace subcommands>]

Set tracing of various sorts.

The types of tracing include events from the trace buffer, or printing
those events.

Run C<help set trace *> for a list of subcommands or C<help set trace>
I<name> for help on a particular trace subcommand.

=head2 See also:

L<C<show trace>|Devel::Trepan::CmdProcessor::Command::Show::Trace>

=cut
HELP
our $SHORT_HELP   = "Set tracing of various sorts.";

@ISA = qw(Devel::Trepan::CmdProcessor::Command::SubsubcmdMgr);

unless (caller) {
    # Demo it.
    # FIXME: DRY with other subcommand manager demo code.
    require Devel::Trepan::CmdProcessor::Mock;
    my ($proc, $cmd) =
	Devel::Trepan::CmdProcessor::Mock::subcmd_setup();
    Devel::Trepan::CmdProcessor::Mock::subcmd_demo_info($proc, $cmd);
    $cmd->run($cmd->{prefix});
    my @args = (@{$cmd->{prefix}}, 'print', 'off');
    $cmd->run(\@args);
}

1;
