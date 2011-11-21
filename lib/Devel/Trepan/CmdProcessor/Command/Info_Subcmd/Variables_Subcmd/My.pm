# -*- coding: utf-8 -*-
# Copyright (C) 2011 Rocky Bernstein <rocky@cpan.org>
use warnings; no warnings 'redefine'; no warnings 'once';
use rlib '../../../../..';
use strict;
use vars qw(@ISA @SUBCMD_VARS);

package Devel::Trepan::CmdProcessor::Command::Info::Variables::My;
use Devel::Trepan::CmdProcessor::Command::Subcmd::Subsubcmd;
use PadWalker qw(peek_my);

use Devel::Trepan::CmdProcessor::Command::Subcmd::Core;
use vars qw(@ISA @SUBCMD_VARS);
our $CMD = "info variables our";
our $MIN_ABBREV = length('o');
our $HELP   = <<"HELP";
${CMD}

List 'my' variables at the current stack level.
HELP
our $SHORT_HELP   = "Information about 'my' variables.";

@ISA = qw(Devel::Trepan::CmdProcessor::Command::SubsubcmdMgr);

sub run($$)
{
    my ($self, $args) = @_;
    # FIXME: combine with My.pm
    my $i = 0;
    while (my ($pkg, $file, $line, $fn) = caller($i++)) { ; };
    my $diff = $i - $DB::stack_depth;
    my $proc = $self->{proc};
    # FIXME: 4 is a magic fixup constant, also found in DB::finish.
    # Remove it.
    my $my_hash = peek_my($diff + $proc->{frame_index} + 4);
    my @names = sort keys %{$my_hash};
    if (scalar @names) {
	$proc->section("my variables");
	$proc->msg($self->{parent}{parent}->columnize_commands(\@names));
    } else {
	$proc->msg("No 'my' variables at this level");
    }
}

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
