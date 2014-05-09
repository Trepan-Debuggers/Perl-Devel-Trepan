# -*- coding: utf-8 -*-
# Copyright (C) 2011, 2014 Rocky Bernstein <rocky@cpan.org>
use warnings; no warnings 'redefine'; no warnings 'once';
use rlib '../../../../..';
use strict;
use vars qw(@ISA @SUBCMD_VARS);

package Devel::Trepan::CmdProcessor::Command::Show::Trace;

use Devel::Trepan::CmdProcessor::Command::Subcmd::Core;
use Devel::Trepan::CmdProcessor::Command::Subcmd::SubsubMgr;
use vars qw(@ISA @SUBCMD_VARS);
our $MIN_ABBREV = length('au');
=pod

=head2 Synopsis:

=cut
our $HELP   = <<"HELP";
=pod

Show tracing of various sorts.

The types of tracing include events from the trace buffer, or printing
those events.

=head2

C<help set trace *> for a list of subcommands or C<help set trace>
I<name> for help on a particular trace subcommand.

=cut
HELP

@ISA = qw(Devel::Trepan::CmdProcessor::Command::SubsubcmdMgr);
our $SHORT_HELP = 'Show tracing event-related controls';

# sub run($$)
# {
#     my ($self, $args) = @_;
#     $self->SUPER;
# }

unless (caller) {
    # Demo it.
    require Devel::Trepan;
    # require_relative '../../mock'
    # dbgr, parent_cmd = MockDebugger::setup('set', false);
    # $cmd              = __PACKAGE__->new(dbgr.core.processor,
    #                                     parent_cmd);
    # $cmd->run(($cmd->prefix  ('string', '30'));

    # for my $prefix qw(s lis foo) {
    #   p [prefix, cmd.complete(prefix)];
    # }
}

1;
