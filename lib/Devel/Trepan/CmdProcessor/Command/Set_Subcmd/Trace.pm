# -*- coding: utf-8 -*-
# Copyright (C) 2011 Rocky Bernstein <rocky@cpan.org>
use warnings; no warnings 'redefine'; no warnings 'once';
use rlib '../../../../..';
use strict;
use vars qw(@ISA @SUBCMD_VARS);

package Devel::Trepan::CmdProcessor::Command::Set::Trace;

use Devel::Trepan::CmdProcessor::Command::Subcmd::Core;
use Devel::Trepan::CmdProcessor::Command::Subcmd::SubsubMgr;
use vars qw(@ISA @SUBCMD_VARS);
our $MIN_ABBREV = length('tr');
our $HELP   = <<"HELP";
Set tracing of various sorts.

The types of tracing include events from the trace buffer, or printing
those events.

See 'help set trace *' for a list of subcommands or 'help set trace
<name>' for help on a particular trace subcommand.
HELP
our $SHORT_HELP   = "Set tracing of various sorts.";

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
