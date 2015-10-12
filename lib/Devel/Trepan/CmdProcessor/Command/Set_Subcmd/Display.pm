# -*- coding: utf-8 -*-
# Copyright (C) 2012, 2014-2015 Rocky Bernstein <rocky@cpan.org>
use warnings; no warnings 'redefine'; no warnings 'once';
use rlib '../../../../..';
use strict;
use vars qw(@ISA @SUBCMD_VARS);

package Devel::Trepan::CmdProcessor::Command::Set::Display;

use Devel::Trepan::CmdProcessor::Command::Subcmd::Core;
use Devel::Trepan::CmdProcessor::Command::Subcmd::SubsubMgr;
use vars qw(@ISA @SUBCMD_VARS);
our $MIN_ABBREV = length('di');
our $SHORT_HELP = 'Set display attributes';
=pod

=head2 Synopsis:

=cut

our $HELP = <<'HELP';
=pod

B<set display> [I<set display subcommands>]

Set display attributes.

Run C<set display *> for a list of subcommands or C<help set display>
I<name> for help on a particular display option.

=head2 See also:

L<C<show display>|Devel::Trepan::CmdProcessor::Command::Show::Display>,
L<C<set debug
eval>|Devel::Trepan::CmdProcessor::Command::Set::Debug::Eval>, and
L<C<set debug
op>|Devel::Trepan::CmdProcessor::Command::Set::Debug::OP>

=cut
HELP

@ISA = qw(Devel::Trepan::CmdProcessor::Command::SubsubcmdMgr);

unless (caller) {
    # Demo it.
    # FIXME: DRY with other subcommand manager demo code.
    require Devel::Trepan::CmdProcessor::Mock;
    my ($proc, $cmd) =
	Devel::Trepan::CmdProcessor::Mock::subcmd_setup();
    Devel::Trepan::CmdProcessor::Mock::subcmd_demo_info($proc, $cmd);
    for my $arg ('ev', 'op', 'foo') {
        my @aref = $cmd->complete_token_with_next($arg);
        printf "%s\n", @aref ? $aref[0]->[0]: 'undef';
    }
    $cmd->run($cmd->{prefix});
    my @args = (@{$cmd->{prefix}}, 'op', 'on');
    $cmd->run(\@args);
}

1;
