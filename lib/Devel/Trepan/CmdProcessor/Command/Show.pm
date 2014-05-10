# -*- coding: utf-8 -*-
# Copyright (C) 2011-2012, 2014 Rocky Bernstein <rocky@cpan.org>
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

our $NAME = set_name();
=pod

=head2 Synopsis:

=cut

our $HELP = <<'HELP';
=pod

B<show> [I<show sub-commmand> ...]

Generic command for showing things about the debugger.  You can
give unique prefix of the name of a subcommand to get information
about just that subcommand.

Type C<show> for a list of show subcommands and what they do.

Type C<help show *> for a list of C<show> subcommands.

=head2 See also:

L<C<show abbrev>|Devel::Trepan::CmdProcessor::Command::Show::Abbrev>,
L<C<show aliases>|Devel::Trepan::CmdProcessor::Command::Show::Aliases>,
L<C<show args>|Devel::Trepan::CmdProcessor::Command::Show::args>,
L<C<show auto>|Devel::Trepan::CmdProcessor::Command::Show::Auto>,
L<C<show basename>|Devel::Trepan::CmdProcessor::Command::Show::Basename>,
L<C<show confirm>|Devel::Trepan::CmdProcessor::Command::Show::Confirm>,
L<C<show debug>|Devel::Trepan::CmdProcessor::Command::Show::Debug>,
L<C<show different>|Devel::Trepan::CmdProcessor::Command::Show::Different>,
L<C<show display>|Devel::Trepan::CmdProcessor::Command::Show::Display>,
L<C<show highlight>|Devel::Trepan::CmdProcessor::Command::Show::Highlight>,
L<C<show interactive>|Devel::Trepan::CmdProcessor::Command::Show::Interactive>,
L<C<show max>|Devel::Trepan::CmdProcessor::Command::Show::Max>,
L<C<show timer>|Devel::Trepan::CmdProcessor::Command::Show::Timer>,
L<C<show trace>|Devel::Trepan::CmdProcessor::Command::Show::Trace>, and
L<C<show version>|Devel::Trepan::CmdProcessor::Command::Show::Version>

=cut

HELP

sub run($$)
{
    my ($self, $args) = @_;
    my $first;
    if (scalar @$args > 1) {
        $first = lc $args->[1];
        my $alen = length('auto');
        splice(@$args, 1, 1, ('auto', substr($first, $alen))) if
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
