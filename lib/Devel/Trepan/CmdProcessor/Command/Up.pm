# Copyright (C) 2011 Rocky Bernstein <rocky@cpan.org>
use warnings; no warnings 'redefine';

use rlib '../../../..';

use Exporter;
# NOTE: The down command  subclasses this, so beware when changing! 
package Devel::Trepan::CmdProcessor::Command::Up;
use if !defined @ISA, Devel::Trepan::CmdProcessor::Command ;

unless (defined(@ISA)) {
    eval <<'EOE';
use constant ALIASES    => qw(u);
use constant CATEGORY   => 'stack';
use constant SHORT_HELP => 'Move frame in the direction of most recent frame';
use constant MIN_ARGS   => 0;     # Need at least this many
use constant MAX_ARGS   => 1; # Need at most this many - undef -> unlimited.
use constant NEED_STACK => 1;
EOE
}

use strict;

use vars qw(@ISA @EXPORT); @ISA = @CMD_ISA; push @ISA, 'Exporter'; 
use vars @CMD_VARS;  # Value inherited from parent
@EXPORT = qw(@CMD_VARS set_name);

our $NAME = set_name();
our $HELP = <<"HELP";
${NAME} [COUNT]

Move the current frame up in the stack trace (to an older frame). 0 is
the most recent frame. If no count is given, move up 1.

See also 'down' and 'frame'.
HELP

sub complete($$)
{ 
    my ($self, $prefix) = @_;
    $self->{proc}->frame_complete($prefix, 1);
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
    $proc->adjust_frame($count, 0);
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
