# -*- coding: utf-8 -*-
# Copyright (C) 2011 Rocky Bernstein <rocky@cpan.org>
use warnings; no warnings 'redefine';
use rlib '../../../..';

package Devel::Trepan::CmdProcessor::Command::Undisplay;
use English qw( -no_match_vars );

use if !defined @ISA, Devel::Trepan::CmdProcessor::Command ;

unless (defined @ISA) {
    eval <<'EOE';
use constant CATEGORY   => 'data';
use constant NEED_STACK => 0;;
use constant SHORT_HELP => 'Cancel some expressions to be displayed when program stops';
use constant MIN_ARGS   => 0;     # Need at least this many
use constant MAX_ARGS   => undef; # Need at most this many - undef -> unlimited.
EOE
}

use strict; use vars qw(@ISA); @ISA = @CMD_ISA;
use vars @CMD_VARS;  # Value inherited from parent

our $NAME = set_name();
our $HELP = <<"HELP";
${NAME} DISPLAY_NUMBER ...
Cancel some expressions to be displayed when program stops.  Arguments
are the code numbers of the expressions to stop displaying.  No
argument means cancel all automatic-display expressions.  "delete
display" has the same effect as this command.  Used "info display" to
see current list of display numbers.
HELP

# This method runs the command
sub run($$) {
    my ($self, $args) = @_;
    my $proc = $self->{proc};
    my @args = @$args; 

    if (scalar @args == 1) {
	if ($proc->confirm('Delete all displays?', 0)) {
	    $proc->{displays}->reset;
	    return;
	}
    }
    shift @args;
    for my $num_str (@args) {
	my $opts = {msg_on_error => sprintf('%s must be a display number', $num_str)};
	my $i = $proc->get_an_int($num_str);
	if ($i) {
	    unless($proc->{displays}->delete($i)) {
		$proc->errmsg("No display number $i");
		return;
	    }
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
