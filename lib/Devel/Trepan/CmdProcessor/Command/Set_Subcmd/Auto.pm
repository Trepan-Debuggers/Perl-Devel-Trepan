# -*- coding: utf-8 -*-
# Copyright (C) 2011 Rocky Bernstein <rocky@cpan.org>
use warnings; no warnings 'redefine'; no warnings 'once';
use rlib '../../../../..';
use strict;
use vars qw(@ISA @SUBCMD_VARS);

package Devel::Trepan::CmdProcessor::Command::Set::Auto;

use Devel::Trepan::CmdProcessor::Command::Subcmd::Core;
use Devel::Trepan::CmdProcessor::Command::Subcmd::SubsubMgr;
use vars qw(@ISA @SUBCMD_VARS);
our $MIN_ABBREV = length('au');
our $HELP   = <<"HELP";
Set controls for things with some sort of \"automatic\" default behavior

See 'help set auto *' for a list of subcommands or 'help set auto <name>' 
for help on a particular trace subcommand.
HELP
our $SHORT_HELP = 
"Set controls for some \"automatic\" default behaviors";

@ISA = qw(Devel::Trepan::CmdProcessor::Command::SubsubcmdMgr);


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
