# -*- coding: utf-8 -*-
# Copyright (C) 2011 Rocky Bernstein <rocky@cpan.org>
use warnings; no warnings 'redefine';
use lib '../../../..';

package Devel::Trepan::CmdProcessor::Command::Delete;
use English;

use if !defined @ISA, Devel::Trepan::CmdProcessor::Command ;

unless (defined @ISA) {
    eval "use constant CATEGORY   => 'breakpoints';";
    eval "use constant NEED_STACK => 0;";
    eval "use constant SHORT_HELP => 'Delete some breakpoints';"
}

use strict; use vars qw(@ISA); @ISA = @CMD_ISA;
use vars @CMD_VARS;  # Value inherited from parent
our $MIN_ARGS   = 0;      # Need at least this many
our $MAX_ARGS   = undef;  # Need at most this many - undef -> unlimited.

our $NAME = set_name();
our $HELP = <<"HELP";
${NAME} [bpnumber [bpnumber...]]  

Delete some breakpoints.

Arguments are breakpoint numbers with spaces in between.  To delete
all breakpoints, give no argument.  those breakpoints.  Without
argument, clear all breaks (but first ask confirmation).
    
See also the "clear" command which clears breakpoints by line/file
number.
HELP

# This method runs the command
sub run($$) {
    my ($self, $args) = @_;
    my $proc = $self->{proc};
    my @args = @$args; 

    if (scalar @args == 1) {
	if ($proc->confirm('Delete all breakpoints?', 0)) {
	    $proc->{brkpts}->reset;
	    return;
	}
    }
    shift @args;
    for my $num_str (@args) {
	my $i = $proc->get_an_int($num_str);
	my $success = $proc->{brkpts}->delete($i) if $i;
	$proc->msg("Deleted breakpoint $i") if $success;
    }
}
        
unless (caller) {
    require Devel::Trepan::CmdProcessor::Mock;
    my $proc = Devel::Trepan::CmdProcessor::Mock::setup();
    # my $cmd = __PACKAGE__->new($proc);
    # $cmd->run([$NAME]);
}

1;
