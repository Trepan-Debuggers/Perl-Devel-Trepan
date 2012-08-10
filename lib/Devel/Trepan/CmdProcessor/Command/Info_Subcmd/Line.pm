# -*- coding: utf-8 -*-
# Copyright (C) 2012 Rocky Bernstein <rockb@cpan.org>
use warnings; no warnings 'redefine'; no warnings 'once';
use rlib '../../../../..';

package Devel::Trepan::CmdProcessor::Command::Info::Line;

use Devel::Trepan::CmdProcessor::Command::Subcmd::Core;

use strict;
use vars qw(@ISA @SUBCMD_VARS);
@ISA = qw(Devel::Trepan::CmdProcessor::Command::Subcmd);
# Values inherited from parent
use vars @Devel::Trepan::CmdProcessor::Command::Subcmd::SUBCMD_VARS;
use constant MAX_ARGS => 1;

our $HELP = 'Line Information about debugged program';
our $MIN_ABBREV = length('li');

sub run($$) 
{
    my ($self, $args) = @_;
    my @args      = @$args; shift @args; shift @args;
    my $proc      = $self->{proc};
    my $frame     = $proc->{frame};
    my $filename  = $proc->filename();
    my $line;

    my $arg_count = scalar @args;
    if ($arg_count == 0) {
	$line = $frame->{line};
    } else {
	if ($args[0] =~ /\d+/) {
	    $line = $args[0];
	} else {
	    $proc->msg("Expecting a line number, got ${args[0]}");
	    return;
	}
    }
    my $m = sprintf "Line %d, file %s", $line, $filename;
    $proc->msg($m);
    if (defined($DB::dbline[$line]) && 0 != $DB::dbline[$line]) {
	$m = sprintf "COP address: 0x%x.", $DB::dbline[$line];
	$proc->msg($m);
    } else {
	$proc->msg("Line not showing as associated with code\n");
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
