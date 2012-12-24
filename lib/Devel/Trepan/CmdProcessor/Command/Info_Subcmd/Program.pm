# -*- coding: utf-8 -*-
# Copyright (C) 2011-2012 Rocky Bernstein <rocky@cpan.org>
use warnings; no warnings 'redefine'; no warnings 'once';
use rlib '../../../../..';

package Devel::Trepan::CmdProcessor::Command::Info::Program;

use Devel::Trepan::CmdProcessor::Command::Subcmd::Core;

use strict;
use vars qw(@ISA @SUBCMD_VARS);
@ISA = qw(Devel::Trepan::CmdProcessor::Command::Subcmd);
# Values inherited from parent
use vars @Devel::Trepan::CmdProcessor::Command::Subcmd::SUBCMD_VARS;

our $SHORT_HELP = 'Information about debugged program and its environment';
our $MIN_ABBREV = length('pr');

our $HELP = <<'HELP';
=pod

Information about debugged program and its environment
=cut
HELP

sub run($$) 
{
    my ($self, $args) = @_;
    my $proc     = $self->{proc};
    my $frame    = $proc->{frame};
    my $line     = $frame->{line};
    my $pkg      = $frame->{pkg};
    my $function = $frame->{fn} if 
	$frame->{fn} && $frame->{fn} ne 'DB::DB';

    my $m;
    if (defined($DB::ini_dollar0) && $DB::ini_dollar0) {
        $m = sprintf "Program: %s.", $DB::ini_dollar0;
        $proc->msg($m);
    }
    $m = sprintf "Program stop event: %s.", $proc->{event};
    $proc->msg($m);
    if (defined($DB::OP_addr)) {
        $m = sprintf "OP address: 0x%x.", $DB::OP_addr;
        $proc->msg($m);
    }
    $proc->msg("Function: $function") if defined $function;
    $proc->msg("Package: $pkg");
    if ('return' eq $proc->{event}) {
        $proc->{commands}{info}->run(['info', 'return']);
    } elsif ('raise' eq  $proc->{event}) {
        # $self->msg($proc->core.hook_arg) if $proc->core.hook_arg;
    }

    if ($DB::brkpt) {
        my $m = sprintf('It is stopped at %sbreakpoint %d.',
                     $DB::brkpt->type eq 'tbrkpt' ? 'temporary ' : '',
                     $DB::brkpt->id);
        $proc->msg($m);
    }
}

unless (caller) {
    require Devel::Trepan;
    # Demo it.
    # require_relative '../../mock'
    # my($dbgr, $parent_cmd) = MockDebugger::setup('show');
    # $cmd = __PACKAGE__->new(parent_cmd);
    # $cmd->run(@$cmd->prefix);
}

# Suppress a "used-once" warning;
$HELP || scalar @SUBCMD_VARS;
