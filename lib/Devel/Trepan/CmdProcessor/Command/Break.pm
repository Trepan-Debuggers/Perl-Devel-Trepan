# -*- coding: utf-8 -*-
# Copyright (C) 2011 Rocky Bernstein <rocky@cpan.org>
use warnings; no warnings 'redefine';
use lib '../../../..';

# require_relative '../../app/condition'

package Devel::Trepan::CmdProcessor::Command::Break;
use English;
use if !defined @ISA, Devel::Trepan::CmdProcessor::Command;
unless (defined(@ISA)) {
    eval "use constant ALIASES    => qw(b);";
    eval "use constant CATEGORY   => 'breakpoints';";
    eval "use constant SHORT_HELP => 'Set a breakpoint';";
}

use strict; use vars qw(@ISA); @ISA = @CMD_ISA;
use vars @CMD_VARS;  # Value inherited from parent

our $MIN_ARGS = 0;
our $MAX_ARGS = undef;  # undef -> unlimited
our $NAME = set_name();
our $HELP = <<"HELP";
${NAME} [LOCATION] [if CONDITION]

Set a breakpoint. If no location is given use the current stopping
point.

Examples:
   ${NAME}                  # set a breakpoint on the current line
   ${NAME} gcd              # set a breakpoint in function gcd
   ${NAME} gcd if \$a == 1   # set a breakpoint in function gcd with 
                          # condition \$a == 1
   ${NAME} 10               # set breakpoint on line 10

See also "tbreak", "delete", "info break" and "condition".
HELP

local $NEED_RUNNING = 1;


#  include Trepan::Condition

# This method runs the command
sub run($$) {
    my ($self, $args) = @_;
    my @args = @$args;
    shift @args;
    my $proc = $self->{proc};
    my $bp;
    my $arg_count = scalar @args;
    if ($arg_count == 0) {
	$bp = $self->{dbgr}->set_break($DB::filename, $DB::lineno);
    } else {
	my ($filename, $line_or_fn, $condition);
	if ($arg_count > 2) {
	    if ($args[0] eq 'if') {
		$line_or_fn = $DB::lineno;
		$filename = $DB::filename;
		unshift @args, $line_or_fn;
	    } else  {
		$filename = $args[0];
		if ($args[1] =~ /\d+/) {
		    $line_or_fn = $args[1];
		    shift @args;
		} elsif ($args[1] eq 'if') {
		    $line_or_fn = $args[0];
		} else {
		    $line_or_fn = $args[0];
		}
	    }
	} else {
	    # $arg_count == 1. 
	    $line_or_fn = $args[0];
	    $filename = $DB::filename;
	}
	shift @args;
	if (scalar @args) {
	    if ($args[0] eq 'if') {
		shift @args;
		$condition = join(' ', @args);
	    } else {
		$proc->errmsg("Expection 'if' to start breakpoint condition;" . 
			      " got ${args[0]}");
	    }
	}
	$bp = $self->{dbgr}->set_break($filename, $line_or_fn, $condition);
	if ($bp) {
	    my $prefix = $bp->type eq 'tbrkpt' ? 
		'Temporary breakpoint' : 'Breakpoint' ;
	    my $id = $bp->id;
	    my $filename = $proc->canonic_file($bp->filename);
	    my $line_num = $bp->line_num;
	    $proc->{brkpts}->add($bp);
	    $proc->msg("$prefix $id set in $filename at line $line_num");
	}
    }
}

unless (caller) {
    require Devel::Trepan::CmdProcessor::Mock;
    my $proc = Devel::Trepan::CmdProcessor::Mock::setup();
    # my $cmd = __PACKAGE__->new($proc);
    # $cmd->run([$NAME]);
}

1;
