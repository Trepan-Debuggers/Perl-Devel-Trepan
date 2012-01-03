# Copyright (C) 2011 Rocky Bernstein <rocky@cpan.org>
use warnings; no warnings 'redefine';

use rlib '../../../..';

package Devel::Trepan::CmdProcessor::Command::Backtrace;
use if !defined @ISA, Devel::Trepan::CmdProcessor::Command ;

unless (defined @ISA) {
    eval <<"EOE";
use constant ALIASES    => qw(bt where T);
use constant CATEGORY   => 'stack';
use constant SHORT_HELP => 'Print backtrace of stack frames';
use constant MIN_ARGS  => 0;   # Need at least this many
use constant MAX_ARGS  => 1;   # Need at most this many - undef -> unlimited.
EOE
}

use strict; use vars qw(@ISA); @ISA = @CMD_ISA; 
use vars @CMD_VARS;  # Value inherited from parent

our $NAME = set_name();
our $HELP = <<"HELP";
${NAME} [count]

Print a stack trace, with the most recent frame at the top.  With a
positive number, print at most many entries. 

An arrow indicates the 'current frame'. The current frame determines
the context used for many debugger commands such as source-line
listing or the 'edit' command.

Examples:
   ${NAME}    # Print a full stack trace
   ${NAME} 2  # Print only the top two entries
HELP

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
    my $opts = {
	basename    => $proc->{settings}{basename},
	current_pos => $proc->{frame_index},
	maxstack    => $proc->{settings}{maxstack},
	maxwidth    => $proc->{settings}{maxwidth},
    };
    my $stack_size = $proc->{stack_size};
    my $count = $stack_size;
    if (scalar @$args > 1) {
        $count = 
	    $proc->get_an_int($args->[1], 
			      {cmdname   => $self->name,
			       min_value => 1});
	return unless defined $count;
    }
    $opts->{count} = $count;
    my @frames = $self->{dbgr}->backtrace($count-1);
    $self->{proc}->print_stack_trace(\@frames, $opts);
}

unless(caller) {
    require Devel::Trepan::DB;
    require Devel::Trepan::Core;
    my $db = Devel::Trepan::Core->new;
    my $intf = Devel::Trepan::Interface::User->new(undef, undef, {readline => 0});
    my $proc = Devel::Trepan::CmdProcessor->new([$intf], $db);

    $proc->{stack_size} = 0;
    my $cmd = __PACKAGE__->new($proc);
    $cmd->run([$NAME]);
}

1;
