# -*- coding: utf-8 -*-
# Copyright (C) 2011 Rocky Bernstein <rocky@cpan.org>
use warnings; no warnings 'redefine';
use rlib '../../../..';

package Devel::Trepan::CmdProcessor::Command::Condition;
use English qw( -no_match_vars );

use if !defined @ISA, Devel::Trepan::Condition ;
use if !defined @ISA, Devel::Trepan::CmdProcessor::Command ;

unless (defined @ISA) {
    eval <<"EOE";
use constant ALIASES    => qw(cond);
use constant CATEGORY   => 'breakpoints';
use constant NEED_STACK => 0;
use constant SHORT_HELP => 
    'Specify a condition on a breakpoint';
use constant MIN_ARGS  => 2;   # Need at least this many
use constant MAX_ARGS  => undef;  # Need at most this many - undef -> unlimited.
EOE
}

use strict; use vars qw(@ISA); @ISA = @CMD_ISA;
use vars @CMD_VARS;  # Value inherited from parent

our $NAME = set_name();
our $HELP = <<"HELP";
${NAME} BP_NUMBER CONDITION

BP_NUMBER is a breakpoint number.  CONDITION is an expression which
must evaluate to True before the breakpoint is honored.  If CONDITION
is absent, any existing condition is removed; i.e., the breakpoint is
made unconditional.

Examples:
   ${NAME} 5 x > 10  # Breakpoint 5 now has condition x > 10
   ${NAME} 5         # Remove above condition

See also "break", "enable" and "disable".
HELP

# This method runs the command
sub run($$) {
    my ($self, $args) = @_;
    my $proc = $self->{proc};
    my $bpnum = $proc->get_an_int($args->[1]);
    my $bp = $proc->{brkpts}->find($bpnum);
    unless ($bp) { 
	$proc->errmsg("No breakpoint number $bpnum");
	return;
    }
    
    my $condition;
    if (scalar @{$args} > 2) {
	my @args = @{$args};
	shift @args; shift @args;
	$condition = join(' ', @args);
	unless (is_valid_condition($condition)) {
	    $proc->errmsg("Invalid condition: $condition");
	    return
	}
    } else {
	$condition = '1';
	$proc->msg('Breakpoint $bp->id is now unconditional.');
    }
    $bp->condition($condition);
}

unless (caller) {
    require Devel::Trepan::CmdProcessor::Mock;
    my $proc = Devel::Trepan::CmdProcessor::Mock::setup();
    # my $cmd = __PACKAGE__->new($proc);
    # $cmd->run([$NAME]);
}

1;
