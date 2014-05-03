# Copyright (C) 2011-2012, 2014 Rocky Bernstein <rocky@cpan.org>
use warnings; no warnings 'redefine';

use rlib '../../../..';

package Devel::Trepan::CmdProcessor::Command::Quit;
use if !@ISA, Devel::Trepan::CmdProcessor::Command ;

unless (@ISA) {
    eval <<'EOE';
use constant ALIASES    => ('quit!', 'q', 'q!');
use constant CATEGORY   => 'running';
use constant SHORT_HELP => 'Gently exit debugged program';
use constant MIN_ARGS   => 0; # Need at least this many
use constant MAX_ARGS   => 2; # Need at most this many - undef -> unlimited.
EOE
}

use strict;

use vars qw(@ISA); @ISA = @CMD_ISA;
use vars @CMD_VARS;  # Value inherited from parent

our $NAME = set_name();
our $HELP = <<'HELP';
=pod

B<quit>[B<!>] [B<unconditionally>] [I<exit-code>]

Gently exit the debugger and debugged program.

The program being debugged is exited via I<exit()> which runs the
Kernel I<at_exit()> finalizers. If a return code is given, that is the
return code passed to I<exit()> E<mdash> presumably the return code that will
be passed back to the OS. If no exit code is given, 0 is used.

=head2 Examples:

 quit                 # quit prompting if we are interactive
 quit unconditionally # quit without prompting
 quit!                # same as above
 quit 0               # same as "quit"
 quit! 1              # unconditional quit setting exit code 1

=head2 See also:

L<C<set confirm>|Devel::Trepan::CmdProcssor::Command::Set::Confirm> and
L<C<kill>|Devel::Trepan::CmdProcessor::Command::Kill>.

=cut
HELP

# This method runs the command
sub run($$)
{
    my ($self, $args) = @_;
    my $proc = $self->{proc};
    my @args = @$args;
    my $unconditional = 0;
    if (scalar(@args) > 1 && $args->[-1] eq 'unconditionally') {
        pop @args;
        $unconditional = 1;
    } elsif (substr($args[0], -1) eq '!') {
        $unconditional = 1;
    }
    unless ($unconditional || $proc->{terminated} ||
            $proc->confirm('Really quit?', 0)) {
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
    no warnings 'once';
    $DB::single = 0;
    $DB::fall_off_on_end = 1;
    $proc->terminated();
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
