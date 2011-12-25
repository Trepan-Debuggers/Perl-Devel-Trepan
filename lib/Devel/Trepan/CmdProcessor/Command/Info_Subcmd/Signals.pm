# -*- coding: utf-8 -*-
# Copyright (C) 2011 Rocky Bernstein <rockbcpan.org>

use warnings; no warnings 'redefine'; no warnings 'once';
use rlib '../../../../..';

package Devel::Trepan::CmdProcessor::Command::Info::Signals;
require Devel::Trepan::Complete; 
use Devel::Trepan::CmdProcessor::Command::Subcmd::Core;


@ISA = qw(Devel::Trepan::CmdProcessor::Command::Subcmd);
# Values inherited from parent
use vars @Devel::Trepan::CmdProcessor::Command::Subcmd::SUBCMD_VARS;

use constant MAX_ARGS => undef;  # Need at most this many - undef -> unlimited.
our $CMD = "info signals";
our $HELP         = <<"EOH";
${CMD} 
${CMD} SIG1 [SIG2 ..]

In the first form a list of the existing signals and actions are shown.

In the second form, list just the given signals and their definitions
are shown.

Signals can be either their signal name or number. For a signal name
the case is not significant and can be prefaced by SIG or not. For a
signal number, you can preface the number with + or -, but both are
ignored. A negative number is the same as its corresponding positive
number.  

See "handle" for descriptions of the settable fields shown
EOH

our $MIN_ABBREV = length('sig');
our $SHORT_HELP = 'What debugger does when program gets various signals';

sub complete($$) {
    my ($self, $prefix) = @_;
    my @matches =Devel::Trepan::Complete::signal_complete($prefix);
    return sort @matches;
}

sub run($$) {
    my ($self, $args) = @_;
    my $proc = $self->{proc};
    my @args = splice(@$args, 2);
    $proc->{dbgr}{sigmgr}->info_signal(\@args);
}

unless(caller) {
    # Demo it.
    # require_relative '../../mock';
    # my $cmd = MockDebugger::sub_setup(__PACKAGE__);
    # my $cmd->run($cmd->{prefix} + %w(u foo));
}

1;
