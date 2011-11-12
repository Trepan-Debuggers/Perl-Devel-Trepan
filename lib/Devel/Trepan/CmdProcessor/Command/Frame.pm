# Copyright (C) 2011 Rocky Bernstein <rocky@cpan.org>
use warnings; no warnings 'redefine';

use rlib '../../../..';

package Devel::Trepan::CmdProcessor::Command::Frame;
use if !defined @ISA, Devel::Trepan::CmdProcessor::Command ;
use strict;

use vars qw(@ISA); @ISA = @CMD_ISA; 
use vars @CMD_VARS;  # Value inherited from parent

our $NAME = set_name();
our $HELP = <<"HELP";
${NAME} [FRAME_NUMBER]

Change the current frame to frame FRAME_NUMBER if specified, or the
most-recent frame, 0, if no frame number specified.

A negative number indicates the position from the other or
least-recently-entered end.  So '$NAME -1' moves to the oldest frame.

Examples:
   $NAME     # Set current frame at the current stopping point
   $NAME 0   # Same as above
   $NAME .   # Same as above. 'current thread' is explicit.
   $NAME . 0 # Same as above.
   $NAME 1   # Move to frame 1. Same as: frame 0; up
   $NAME -1  # The least-recent frame

See also 'up', 'down' 'where' and 'info thread'.
HELP

use constant CATEGORY   => 'stack';
use constant SHORT_HELP => 'Print backtrace of stack frames';
our $MAX_ARGS     = 1;  # Need at most this many
our $NEED_STACK   = 1;

sub complete($$)
{ 
    my ($self, $prefix) = @_;
    $self->{proc}->frame_complete($prefix);
}
  
# This method runs the command
sub run($$)
{
    my ($self, $args) = @_;
    my $proc = $self->{proc};
    my $position_str;

    if (scalar @$args == 1) {
	# Form is: "frame" which means "frame 0"
	$position_str = '0';
    } elsif (scalar @$args == 2) {
	# Form is: "frame position"
	$position_str = $args->[1];
    }

    my ($low, $high) = $proc->frame_low_high(0);
    my $opts= {
	'msg_on_error' => 
	    "The '${NAME}' command requires a frame number. Got: ${position_str}",
	min_value => $low, 
	max_value => $high
    };
    my $frame_num = $proc->get_an_int($position_str, $opts);
    return unless defined $frame_num;
    $proc->adjust_frame($frame_num, 1);
}

unless (caller) {
    require Devel::Trepan::DB;
    require Devel::Trepan::Core;
    my $db = Devel::Trepan::Core->new;
    my $intf = Devel::Trepan::Interface::User->new;
    my $proc = Devel::Trepan::CmdProcessor->new([$intf], $db);
    $proc->{stack_size} = 0;
    my $cmd = __PACKAGE__->new($proc);
    $cmd->run([$NAME, 0]);
}

1;
