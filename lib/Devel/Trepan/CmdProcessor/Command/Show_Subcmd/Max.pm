# -*- coding: utf-8 -*-
# Copyright (C) 2011-2012 Rocky Bernstein <rocky@cpan.org>
use warnings; no warnings 'redefine'; no warnings 'once';
use rlib '../../../../..';
use strict;
use vars qw(@ISA @SUBCMD_VARS);

package Devel::Trepan::CmdProcessor::Command::Show::Max;

use Devel::Trepan::CmdProcessor::Command::Subcmd::Core;
use Devel::Trepan::CmdProcessor::Command::Subcmd::SubsubMgr;
use vars qw(@ISA @SUBCMD_VARS);
our $MIN_ABBREV = length('ma');
our $HELP   = <<"HELP";
Show maximum length setting on things which may have unbounded size.

See C<help show max *> for a list of subcommands or C<help show debug
I<name>> for help on a particular trace subcommand.
HELP

our $SHORT_HELP   = 'Show "maximum length" settings';
@ISA = qw(Devel::Trepan::CmdProcessor::Command::SubsubcmdMgr);


  # def run(args)
  #   puts "foo"
  #   require 'trepanning'
  #   Trepan.debug
  #   super
  # end

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
