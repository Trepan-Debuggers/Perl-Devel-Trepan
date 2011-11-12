# Copyright (C) 2011 Rocky Bernstein <rocky@cpan.org>
use warnings; no warnings 'redefine';

use rlib '../../../..';

package Devel::Trepan::CmdProcessor::Command::Down;
use if !defined @ISA, Devel::Trepan::CmdProcessor::Command ;
use strict;

use vars qw(@ISA); @ISA = qw(Devel::Trepan::CmdProcessor::Command);
use vars @CMD_VARS;  # Value inherited from parent

our $NAME = set_name();
our $HELP = <<"HELP";
${NAME} [COUNT]

Move the current frame down in the stack trace (to a newer frame). 0
is the most recent frame. If no count is given, move down 1.

See also 'up' and 'frame'.
HELP

use constant ALIASES    => qw(u);
use constant CATEGORY   => 'stack';
use constant SHORT_HELP => 'Move frame in the direction of the least recent frame';
our $MAX_ARGS     = 1;  # Need at most this many
our $NEED_STACK   = 1;

sub complete($$)
{ 
    my ($self, $prefix) = @_;
    $self->{proc}->frame_complete($prefix, -1);
}
  
# This method runs the command
sub run($$)
{
    my ($self, $args) = @_;
    my $proc = $self->{proc};
    my $count_str = $args->[1] // 1;
    my ($low, $high) = $proc->frame_low_high(0);
    my $opts= {
	'msg_on_error' => 
	    "The '${NAME}' command requires a frame number. Got: ${count_str}",
	min_value => $low, 
	max_value => $high
    };
    my $count = $proc->get_an_int($count_str, $opts);
    return unless defined $count;
    $proc->adjust_frame(-$count, 0);
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
