# -*- coding: utf-8 -*-
# Copyright (C) 2012 Rocky Bernstein <rocky@cpan.org>
use warnings; no warnings 'redefine';

use rlib '../../../..';

package Devel::Trepan::BWProcessor::Command::Step;
=head1 Step

step statements

=head2 Input Fields

 { command  => 'step',
   [count   => <integer>],
 }

If I<skip_count> is given that many statements will be stepped. If it
is not given, 1 is used, i.e. stop at the next statement.

=head2 Output Fields

 { name     => 'step',
   count    => <integer>,
   [errmsg  => <error-message-array>]
   [msg     => <message-text array>]
 }

=cut

use if !@ISA, Devel::Trepan::BWProcessor::Command ;

use strict;
use vars qw(@ISA); @ISA = @CMD_ISA;
use vars @CMD_VARS;  # Value inherited from parent

$NAME = set_name();

# This method runs the command
sub run($$) {
    my ($self, $args) = @_;

    my $proc = $self->{proc};
    $proc->{skip_count} = $args->{count} ? 
	($args->{count} - 1) : 0;
    # FIXME: Handle opts later
    # $proc->step($opts)
    $proc->{response}{count} = $proc->{skip_count} + 1;
    $proc->step()
}

unless (caller) {
  # require_relative '../mock'
  # dbgr, cmd = MockDebugger::setup
  # p cmd.run([cmd.name])
}

1;
