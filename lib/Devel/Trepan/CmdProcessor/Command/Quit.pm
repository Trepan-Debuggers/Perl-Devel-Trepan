# Copyright (C) 2011 Rocky Bernstein <rocky@cpan.org>
use warnings; no warnings 'redefine';

use lib '../../../..';

package Devel::Trepan::CmdProcessor::Command::Quit;
use if !defined @ISA, Devel::Trepan::CmdProcessor::Command ;
use strict;

use vars qw(@ISA); @ISA = @CMD_ISA; 
use vars @CMD_VARS;  # Value inherited from parent

our $MIN_ARGS     = 0;  # Need at most this many
our $MAX_ARGS     = 2;  # Need at most this many
our $NAME = set_name();
our $HELP = <<"HELP";
${NAME}[!] [unconditionally] [exit code] 

gentle termination

The program being debugged is exited via exit() which runs the Kernel
at_exit finalizers. If a return code is given, that is the return code
passed to exit() - presumably the return code that will be passed back
to the OS. If no exit code is given, 0 is used.

Examples: 
  ${NAME}                 # quit prompting if we are interactive
  ${NAME} unconditionally # quit without prompting
  ${NAME}!                # same as above
  ${NAME} 0               # same as "quit"
  ${NAME}! 1              # unconditional quit setting exit code 1

See also the commands "exit" and "kill".
HELP

use constant ALIASES    => ('quit!', 'q', 'q!');
use constant CATEGORY   => 'support';
use constant SHORT_HELP => 'Quit program - gently';


# FIXME: Combine 'quit' and 'exit'. The only difference is whether
# exit! or exit is used.

# This method runs the command
sub run($$)
{
    my ($self, $args) = @_;
    my @args = @$args;
    my $unconditional = 0;
    if (scalar(@args) > 1 && $args->[-1] eq 'unconditionally') {
        pop @args;
	$unconditional = 1;
    } elsif (substr($args[0], -1) eq '!') {
        $unconditional = 1;
    }
    unless ($unconditional || $self->{proc}->confirm('Really quit?', 0)) {
	$self->msg('Quit not confirmed.');
	return;
    }

    my $exitrc = 0;
    if (scalar(@args) > 1) {
	if ($args[1] =~ /\d+/) {
	    $exitrc = $args[1];
	} else {
	    $self->errmsg("Bad an Integer return type \"$args[1]\"");
	    return;
	}
    }
    $self->{DB_single} = $DB::single = 0;
    $self->{proc}->{interfaces} = [];
    # No graceful way to stop threads...
    exit $exitrc;
}

unless (caller) {
    require Devel::Trepan::CmdProcessor::Mock;
    my $proc = Devel::Trepan::CmdProcessor->new(undef, 'bogus');
    my $cmd = __PACKAGE__->new($proc);
    my $child_pid = fork;
    if ($child_pid == 0) { 
	$cmd->run([$NAME, 'unconditionally']);
    } else {
	wait;
    }
    $cmd->run([$NAME, '5', 'unconditionally']);
}

1;
