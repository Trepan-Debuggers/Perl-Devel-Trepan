# -*- coding: utf-8 -*-
# Copyright (C) 2011-2012, 2014 Rocky Bernstein <rocky@cpan.org>
use warnings; no warnings 'redefine';

use rlib '../../../..';

package Devel::Trepan::CmdProcessor::Command::TBreak;

use if !@ISA, Devel::Trepan::CmdProcessor::Command ;

unless (@ISA) {
    eval <<'EOE';
use constant CATEGORY => 'breakpoints';
use constant SHORT_HELP => 'Set a one-time breakpoint';
use constant MIN_ARGS   => 0;     # Need at least this many
use constant MAX_ARGS   => undef; # Need at most this many - undef -> unlimited.
use constant NEED_STACK => 1;
EOE
}

use strict;
use vars qw(@ISA); @ISA = @CMD_ISA;
use vars @CMD_VARS;  # Value inherited from parent

our $NAME = set_name();
=pod

=head2 Synopsis:

=cut
our $HELP = <<'HELP';
=pod

B<tbreak> [I<location>]

Set a one-time breakpoint. The breakpoint is removed after it is hit.
If no location is given use the current stopping point.

=head2 Examples:

   tbreak
   tbreak 10 # set breakpoint on line 10

When a breakpoint is hit the event icon is C<x1>.

=head2 See also:

L<C<break>|Devel::Trepan::CmdProcessor::Break> and
C<help breakpoints>.

=cut
HELP

# This method runs the command
sub run($$) {
    my ($self, $args) = @_;
    no warnings 'once';
    $self->{dbgr}->set_tbreak($DB::filename, $args->[1]);
}

unless (caller) {
  # require_relative '../mock'
  # dbgr, cmd = MockDebugger::setup
  # p cmd.run([cmd.name])
}

1;
