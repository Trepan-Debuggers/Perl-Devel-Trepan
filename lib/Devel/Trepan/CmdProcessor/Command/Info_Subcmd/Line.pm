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
    my $end_line  = undef;

    my $arg_count = scalar @args;
    if ($arg_count == 0) {
	$line = $frame->{line};
    } else {
	if ($args[0] =~ /\d+/) {
	    $line = $args[0];
	} else {
	    my @matches = $proc->{dbgr}->subs($args[0]);
	    if (scalar(@matches) == 1) {
		$filename = $matches[0][0];
		$line     = $matches[0][1];
		$end_line = $matches[0][2];
	    } else {
		$proc->msg("Expecting a line number or fully qualified function; got ${args[0]}");
		return;
	    }
	}
    }
    my $m;
    my $canonic = $proc->canonic_file($filename);
    if (defined $end_line) {
	$m = sprintf("Function %s in file %s lines %d..%d", 
		     $args[0], $canonic, $line, $end_line);
    } else {
	$m = sprintf "Line %d, file %s", $line, $canonic;
    }
    $proc->msg($m);
    local(*DB::dbline) = "::_<$filename";
    if (defined($DB::dbline[$line]) && 0 != $DB::dbline[$line]) {
	$m = sprintf "COP address: 0x%x.", $DB::dbline[$line];
	$proc->msg($m);
    } else {
	$proc->msg("Line not showing as associated with code\n") 
	    unless $end_line;
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
