# -*- coding: utf-8 -*-
# Copyright (C) 2011-2012 Rocky Bernstein <rocky@cpan.org>
use warnings; no warnings 'redefine';

use rlib '../../../..';

# rlib '../running'
# rlib '../../app/breakpoint' # FIXME: possibly temporary

package Devel::Trepan::CmdProcessor::Command::Continue;

use if !@ISA, Devel::Trepan::CmdProcessor::Command ;

unless (@ISA) {
    eval <<'EOE';
    use constant ALIASES    => qw(c cont);
    use constant CATEGORY   => 'running';
    use constant SHORT_HELP => 'Continue running until end or brkpt';
    use constant MIN_ARGS   => 0;  # Need at least this many
    use constant MAX_ARGS   => 2;  # Need at most this many
    use constant NEED_STACK => 1;
EOE
}

use strict;
use vars qw(@ISA);
@ISA = @CMD_ISA;
use vars @CMD_VARS;  # Value inherited from parent

our $NAME = set_name();
our $HELP = <<"HELP";
=pod

continue [I<location>]

Leave the debugger loop and continue execution. Subsequent entry to
the debugger however may occur via breakpoints or explicit calls, or
exceptions.

If a parameter is given, a temporary breakpoint is set at that position
before continuing. 

=head2 Examples:

 continue
 continue 10    # continue to line 10
 continue gcd   # continue to first instruction of method gcd

See also L<C<step>|Devel::Trepan::CmdProcessor::Command::Step>,
L<C<next>|Devel::Trepan::CmdProcessor::Command::Next>,
L<C<finish>|Devel::Trepan::CmdProcessor::Command::Finis> commands and
C<help location>.

=cut

HELP


# This method runs the command
sub run($$) {
    my ($self, $args) = @_;
    $self->{proc}->continue($args);
}

if (__FILE__ eq $0) {
  # require_relative '../mock'
  # dbgr, cmd = MockDebugger::setup
  # p cmd.run([cmd.name])
}

1;
