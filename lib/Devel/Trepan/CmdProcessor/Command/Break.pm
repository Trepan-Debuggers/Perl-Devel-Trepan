# -*- coding: utf-8 -*-
# Copyright (C) 2011 Rocky Bernstein <rocky@cpan.org>
use warnings; no warnings 'redefine';
use lib '../../../..';

# require_relative '../../app/condition'

package Devel::Trepan::CmdProcessor::Command::Break;
use English;
use if !defined @ISA, Devel::Trepan::CmdProcessor::Command ;
use strict; use vars qw(@ISA); @ISA = @CMD_ISA;
use vars @CMD_VARS;  # Value inherited from parent

our $NAME = set_name();
our $HELP = <<"HELP";
${NAME} [LOCATION]

Set a breakpoint. If no location is given use the current stopping
point.  Set a breakpoint. 

Examples:
   ${NAME}
   ${NAME} 10               # set breakpoint on line 10

See also "tbreak".
HELP

use constant ALIASES    => qw(b);
use constant CATEGORY   => 'breakpoints';
use constant SHORT_HELP => 'Set a breakpoint';
local $NEED_RUNNING = 1;


#  include Trepan::Condition

# This method runs the command
sub run($$) {
    my ($self, $args) = @_;
    my $bp = $self->{dbgr}->set_break($DB::filename, $args->[1]);
    my $proc = $self->{proc};
    $proc->{brkpts}->add($bp);
}

unless (caller) {
    require Devel::Trepan::CmdProcessor::Mock;
    my $proc = Devel::Trepan::CmdProcessor::Mock::setup();
    # my $cmd = __PACKAGE__->new($proc);
    # $cmd->run([$NAME]);
}

1;
