# Copyright (C) 2011 Rocky Bernstein <rocky@cpan.org>
use warnings; no warnings 'redefine';

use lib '../../../..';

# Debugger "down" command. Is the same as the "up" command with the 
# direction (set by DIRECTION) reversed.
package Devel::Trepan::CmdProcessor::Command::Down;
use if !defined @ISA, Devel::Trepan::CmdProcessor::Command::Up ;
use strict;

use vars qw(@ISA); @ISA = qw(Devel::Trepan::CmdProcessor::Command::Up);
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
use constant SHORT_HELP => 'Move frame in the direction of the caller of the last-selected frame';
our $MAX_ARGS     = 1;  # Need at most this many
our $NEED_STACK   = 1;

sub complete($$)
{ 
    my ($self, $prefix) = @_;
    $self->{proc}->frame_complete($prefix, $self->{direction});
}
  
sub new($$)
{
    my ($class, $proc) = @_;
    my $self = Devel::Trepan::CmdProcessor::Command::new($class, $proc);
    $self->{direction} = -1; # +1 for down.
    bless $self, $class;
    $self;
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
