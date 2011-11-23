# -*- coding: utf-8 -*-
# Copyright (C) 2011 Rocky Bernstein <rocky@cpan.org>
use warnings; no warnings 'redefine'; no warnings 'once';
use feature 'switch';
use rlib '../../../../..';
use strict;
use vars qw(@ISA @SUBCMD_VARS);

package Devel::Trepan::CmdProcessor::Command::Info::Variables::My;
use Devel::Trepan::CmdProcessor::Command::Subcmd::Subsubcmd;
use PadWalker qw(peek_my);
use Data::Dumper;

use Devel::Trepan::CmdProcessor::Command::Subcmd::Core;

use vars qw(@ISA @SUBCMD_VARS);
our $CMD = "info variables our";
our $MIN_ABBREV = length('o');
our $HELP   = <<"HELP";
${CMD}
${CMD} -v
${CMD} VAR1 [VAR2...]

Lists 'my' variables at the current frame. Use the frame changing
commands like 'up', 'down' or 'frame' set the current frame.

In the first form, give a list of 'my' variable names only. 
In the second form, list variable names and values
In the third form, list variable names and values of VAR1, etc.

See also 'set variable', and frame changing commands
HELP
our $SHORT_HELP   = "Information about 'my' variables.";

@ISA = qw(Devel::Trepan::CmdProcessor::Command::SubsubcmdMgr);

sub show_var($$$) 
{
    my ($proc, $var_name, $ref) = @_;
    my $dumper;
    given (substr($var_name, 0, 1)) {
	when ('$') { 
	    $dumper = Data::Dumper->new([${$ref}]);
	    $dumper->Useqq(0);
	    $dumper->Terse(1);
	    $dumper->Indent(0);
	    $proc->msg("$var_name = ".  $dumper->Dump);
	    }
	when ('@') { 
	    $dumper = Data::Dumper->new([$ref]); 
	    $dumper->Useqq(0);
	    $dumper->Terse(1);
	    $dumper->Indent(0);
	    $proc->msg("$var_name = ".  $dumper->Dump);
	}
	when ('%') { 
	    $dumper = Data::Dumper->new([$ref], [$var_name]);
	    $dumper->Useqq(0);
	    $dumper->Terse(0);
	    $dumper->Indent(0);
	    $proc->msg($dumper->Dump);
	}
	default    {
	    $dumper = Data::Dumper->new([$ref], [$var_name]); 
	    $dumper->Useqq(0);
	    $dumper->Terse(1);
	    $dumper->Indent(0);
	    $proc->msg($dumper->Dump);
	}
    };
}

sub run($$)
{
    my ($self, $args) = @_;
    my @ARGS = @${args};
    shift @ARGS; shift @ARGS; shift @ARGS;

    # FIXME: combine with My.pm
    my $i = 0;
    while (my ($pkg, $file, $line, $fn) = caller($i++)) { ; };
    my $diff = $i - $DB::stack_depth;
    my $proc = $self->{proc};

    # FIXME: 4 is a magic fixup constant, also found in DB::finish.
    # Remove it.
    my $my_hash = peek_my($diff + $proc->{frame_index} + 4);
    my @names = sort keys %{$my_hash};

    if (0 == scalar @ARGS) {
	if (scalar @names) {
	    $proc->section("my variables");
	    $proc->msg($self->{parent}{parent}->columnize_commands(\@names));
	} else {
	    $proc->errmsg("No 'my' variables at this level");
	}
    } else {
	if ($ARGS[0] eq '-v') {
	    if (scalar @names) {
		$proc->section("my variables");
		for my $name (@names) {
		    show_var($proc, $name, $my_hash->{$name});
		}
	    } else {
		$proc->errmsg("No 'my' variables at this level");
	    }
	} else {
	    for my $name (@ARGS) {
		if (exists($my_hash->{$name})) {
		    show_var($proc, $name, $my_hash->{$name});
		} else {
		    $proc->errmsg("No 'my' variable $name found at this level");
		}
	    }
	}
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
