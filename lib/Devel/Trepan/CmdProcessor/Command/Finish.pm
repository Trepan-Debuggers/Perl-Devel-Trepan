# -*- coding: utf-8 -*-
# Copyright (C) 2011-2014 Rocky Bernstein <rocky@cpan.org>
use warnings; use utf8;

use rlib '../../../..';

# rlib '../running'
# rlib '../../app/breakpoint' # FIXME: possibly temporary

package Devel::Trepan::CmdProcessor::Command::Finish;

use if !@ISA, Devel::Trepan::CmdProcessor::Command ;
use vars qw(@ISA);
unless (@ISA) {
    eval <<'EOE';
    use constant ALIASES    => qw(fin);
    use constant CATEGORY   => 'running';
    use constant SHORT_HELP => 'Step to end of current method (step out)';
    use constant MIN_ARGS   => 0;  # Need at least this many
    use constant MAX_ARGS   => 1;  # Need at most this many
    use constant NEED_STACK => 1;
EOE
}

use strict;
@ISA = @CMD_ISA;
use vars @CMD_VARS;  # Value inherited from parent

our $NAME = set_name();
our $HELP = <<'HELP';
=pod

finish [I<levels>]

Continue execution until the program is about to leave the current
function. Sometimes this is called "step out".

When integer I<levels> is specified, that many frame levels need to be
popped. The default is 1.

See the C<break> command if you want to stop at a particular point in a
program. In general, C<finish>, C<step> and C<next> may slow a program down
while C<break> will have less overhead.

=cut
HELP

no warnings 'redefine';

# This method runs the command
sub run($$) {
    my ($self, $args) = @_;
    my $proc = $self->{proc};
    my $event = $proc->{event};
    if ($event eq 'return') {
        $proc->errmsg("Can't run ${NAME} while inside a return. Step and try again.");
        return;
    } elsif ($event eq 'call') {
        $proc->errmsg("Can't run ${NAME} while inside a call. Step and try again.");
	return;
    }

    my ($opts, $level_count) = ({}, 1);
    if (scalar @$args != 1) {
        # Form is not "finish" which means "finish 1"
        my $count_str = $args->[1];
        $opts = {
            msg_on_error =>
                "The '${NAME}' command argument must eval to an integer. Got: ${count_str}",
                min_value => 1
        };
        my $count = $proc->get_an_int($count_str, $opts);
        return unless defined $count;
        $level_count = $count;
    }
    $proc->finish($level_count);
}

unless (caller) {
  # require_relative '../mock'
  # dbgr, cmd = MockDebugger::setup
  # p cmd.run([cmd.name])
}

1;
