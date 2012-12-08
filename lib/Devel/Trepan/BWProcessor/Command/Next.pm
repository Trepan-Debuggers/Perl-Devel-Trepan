# -*- coding: utf-8 -*-
# Copyright (C) 2011-2012 Rocky Bernstein <rocky@cpan.org>
use warnings; no warnings 'redefine';

use rlib '../../../..';

# require_relative '../../app/condition'

package Devel::Trepan::CmdProcessor::Command::Next;

use if !@ISA, Devel::Trepan::CmdProcessor::Command ;

unless (@ISA) {
    eval <<'EOE';
    use constant ALIASES    => qw(n next+ next- n+ n-);
    use constant CATEGORY   => 'running';
    use constant SHORT_HELP => 'Step program without entering called functions';
    use constant MIN_ARGS   => 0; # Need at least this many
    use constant MAX_ARGS   => 1; # Need at most this many - 
                                  # undef -> unlimited.
    use constant NEED_STACK => 1;
EOE
}

use strict;
use vars qw(@ISA); @ISA = @CMD_ISA;
use vars @CMD_VARS;  # Value inherited from parent

our $NAME = set_name();

# This method runs the command
sub run($$) {
    my ($self, $args) = @_;
    my $proc = $self->{proc};
    my $opts = $proc->parse_next_step_suffix($args->[0]);
    
    # FIXME: parse and adjust step count
    $proc->{skip_count} = 0;

    $proc->next($opts);
}

unless (caller) {
  # require_relative '../mock'
  # dbgr, cmd = MockDebugger::setup
  # p cmd.run([cmd.name])
}

1;
