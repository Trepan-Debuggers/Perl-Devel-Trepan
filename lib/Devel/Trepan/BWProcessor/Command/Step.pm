# -*- coding: utf-8 -*-
# Copyright (C) 2012 Rocky Bernstein <rocky@cpan.org>
use warnings; no warnings 'redefine';

use rlib '../../../..';

# require_relative '../../app/condition'

package Devel::Trepan::BWProcessor::Command::Step;

use if !@ISA, Devel::Trepan::BWProcessor::Command ;

use strict;
use vars qw(@ISA); @ISA = @CMD_ISA;
use vars @CMD_VARS;  # Value inherited from parent

$NAME = set_name();

# This method runs the command
sub run($$) {
    my ($self, $args) = @_;

    my $proc = $self->{proc};
    $proc->{skip_count} = $args->{skip_count} || 0;
    # FIXME: Handle opts later
    # $proc->step($opts)
    $proc->step()
}

unless (caller) {
  # require_relative '../mock'
  # dbgr, cmd = MockDebugger::setup
  # p cmd.run([cmd.name])
}

1;
