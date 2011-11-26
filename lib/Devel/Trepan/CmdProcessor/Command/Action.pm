# -*- coding: utf-8 -*-
# Copyright (C) 2011 Rocky Bernstein <rocky@cpan.org>
use warnings; no warnings 'redefine';
use rlib '../../../..';

package Devel::Trepan::CmdProcessor::Command::Action;
use English qw( -no_match_vars );

use if !defined @ISA, Devel::Trepan::Condition ;
use if !defined @ISA, Devel::Trepan::CmdProcessor::Command ;

unless (defined @ISA) {
    eval <<"EOE";
use constant ALIASES    => qw(a);
use constant CATEGORY   => 'breakpoints';
use constant NEED_STACK => 0;
use constant SHORT_HELP => 'Set an action to be done before the line is executed.'
use constant MIN_ARGS  => 2;      # Need at least this many
use constant MAX_ARGS  => undef;  # Need at most this many - undef -> unlimited.
EOE
}

use strict; use vars qw(@ISA); @ISA = @CMD_ISA;
use vars @CMD_VARS;  # Value inherited from parent

our $NAME = set_name();
our $HELP = <<"HELP";
${NAME} POSITION Perl-statement 

Set an action to be done before the line is executed. If line is
'.', set an action on the line about to be executed. The sequence
of steps taken by the debugger is:

1. check for a breakpoint at this line 
2. print the line if necessary (tracing) 
3. do any actions associated with that line 
4. prompt user if at a breakpoint or in single-step 
5. evaluate line 

For example, this will print out \$foo every time line 53 is passed:

Examples:
   ${NAME} 53 print "DB FOUND \$foo\\n"

See also "break", "enable" and "disable".
HELP

# This method runs the command
sub run($$) {
    my ($self, $args) = @_;
    my $proc = $self->{proc};
    my $frame = $proc->{frame};
    my @args = @$args;
    shift @args;

    my ($filename, $lineno, $fn, $gobble_count, $rest) = 
	$proc->parse_position(\@args, 0); # should be: , 1);
    shift @args if $gobble_count-- > 0;
    shift @args if $gobble_count-- > 0;
    # error should have been shown previously

    my $action_expression = join(' ', @args);
    unless (is_valid_condition($action_expression)) {
	$proc->errmsg("Invalid action: $action_expression");
	return
    }
    my $action = $self->{dbgr}->set_action($lineno, $filename, 
					   $action_expression);
    if ($action) {
	my $id = $action->id;
	my $filename = $proc->canonic_file($action->filename);
	my $line_num = $action->line_num;
	$proc->{actions}->add($action);
	$proc->msg("Action $id set in $filename at line $line_num");

    }
}

unless (caller) {
    require Devel::Trepan::CmdProcessor::Mock;
    my $proc = Devel::Trepan::CmdProcessor::Mock::setup();
    # my $cmd = __PACKAGE__->new($proc);
    # $cmd->run([$NAME]);
}

1;
