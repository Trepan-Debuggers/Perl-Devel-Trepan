# -*- coding: utf-8 -*-
# Copyright (C) 2011 Rocky Bernstein <rockbcpan.org>

use warnings; no warnings 'redefine'; no warnings 'once';
use rlib '../../../../..';

package Devel::Trepan::CmdProcessor::Command::Info::Macros;
use Devel::Trepan::CmdProcessor::Command::Subcmd::Core;

@ISA = qw(Devel::Trepan::CmdProcessor::Command::Subcmd);
# Values inherited from parent
use vars @Devel::Trepan::CmdProcessor::Command::Subcmd::SUBCMD_VARS;

use constant MAX_ARGS => undef;  # Need at most this many - undef -> unlimited.
our $CMD = "show macros";
our $HELP         = <<"EOH";
${CMD} 
${CMD} *
${CMD} MACRO1 [MACRO2 ..]

In the first form a list of the existing macro names are shown
in column format.

In the second form, all macro names and their definitions are show.

In the last form the only definitions of the given macro names is shown.
show macro [NAME1 NAME2 ...] 

If macros names are given, show their definition. If left blank, show
all macro names
EOH

our $MIN_ABBREV = length('ma');
our $SHORT_HELP = "Show defined macros";

# sub complete($$) {
# {
#     my ($self, $prefix) = @_;
#     my @cmds = sort keys %{$proc->{macros}};
#     Trepan::Complete.complete_token(@cmds, $prefix);
# }

sub run($$) {
    my ($self, $args) = @_;
    my $proc = $self->{proc};
    my @args = @$args;
    if (scalar(@args) > 2) {
    	shift @args; shift @args;
    	for my $macro_name (@args) {
    	    if (exists $proc->{macros}{$macro_name}) {
    		my $msg = sprintf("%s: %s", $macro_name, 
				  $proc->{macros}{$macro_name}->[1]);
    		$proc->msg($msg);
    	    } else {
    		$proc->msg("$macro_name is not a defined macro");
    	    }
    	}
    } else {
	my @macros = keys %{$proc->{macros}};
	if (scalar @macros == 0) {
	    $proc->msg("No macros defined.");
	} else {
	    $proc->section("List of macro names currently defined:");
	    my @cmds = sort @macros;
	    $proc->msg($self->{cmd}->columnize_commands(\@cmds));
	}
   }
}

unless(caller) {
    # Demo it.
    # require_relative '../../mock';
    # my $cmd = MockDebugger::sub_setup(__PACKAGE__);
    # my $cmd->run($cmd->{prefix} + %w(u foo));
}

1;
