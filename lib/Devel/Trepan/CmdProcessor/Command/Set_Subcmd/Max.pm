# -*- coding: utf-8 -*-
# Copyright (C) 2011-2014 Rocky Bernstein <rocky@cpan.org>
use warnings; no warnings 'redefine'; no warnings 'once';
use rlib '../../../../..';
use strict;
use vars qw(@ISA @SUBCMD_VARS);

package Devel::Trepan::CmdProcessor::Command::Set::Max;

use Devel::Trepan::CmdProcessor::Command::Subcmd::Core;
use Devel::Trepan::CmdProcessor::Command::Subcmd::SubsubMgr;
use vars qw(@ISA @SUBCMD_VARS);
our $MIN_ABBREV = length('ma');
=pod

=head2 Synopsis:

=cut

our $HELP   = <<"HELP";
=pod

B<set max> I<set max subcommands>

Set maximum length for things which may have unbounded size.

Run C<help set max *> for a list of subcommands or C<help set max I<name>>
for help on a particular max setting.

=head2 See also:

L<C<show max>|Devel::Trepan::CmdProcessor::Command::Show::Max>

=cut
HELP
our $SHORT_HELP = "Set maximum length sizes of various things";

@ISA = qw(Devel::Trepan::CmdProcessor::Command::SubsubcmdMgr);

unless (caller) {
    # Demo it.
    require Devel::Trepan;
    # require_relative '../../mock'
    # dbgr, parent_cmd = MockDebugger::setup('set', false)
    # cmd              = Trepan::SubSubcommand::SetMax.new(dbgr.core.processor,
    #                                                      parent_cmd)
    # cmd.run(cmd.prefix + ['string', '30'])

    # %w(s lis foo).each do |prefix|
    #   p [prefix, cmd.complete(prefix)]
    # end
}

1;
