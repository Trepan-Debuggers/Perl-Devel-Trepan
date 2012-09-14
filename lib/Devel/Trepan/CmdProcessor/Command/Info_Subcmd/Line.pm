# -*- coding: utf-8 -*-
# Copyright (C) 2012 Rocky Bernstein <rocky@cpan.org>
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

our $SHORT_HELP = 'Line Information about debugged program';
our $MIN_ABBREV = length('li');

our $HELP = <<'HELP';
=pod

Line Information about debugged program.
=cut
HELP


sub run($$) 
{
    my ($self, $args) = @_;
    my @args      = @$args; shift @args; shift @args;
    my $proc      = $self->{proc};
    my $frame     = $proc->{frame};
    my $filename  = $proc->filename();
    my ($line, $first_arg, $end_line);

    my $arg_count = scalar @args;
    if ($arg_count == 0) {
        $line = $frame->{line};
    } else {
        $first_arg = $args[0];
        if ($first_arg =~ /\d+/) {
            $line = $first_arg;
        } else {
            my @matches = $proc->{dbgr}->subs($first_arg);
            unless (scalar(@matches)) {
                # Try with current package name
                $first_arg = $proc->{frame}{pkg} . '::' . $first_arg;
                @matches = $proc->{dbgr}->subs($first_arg);
            }
            if (scalar(@matches) == 1) {
                $filename = $matches[0][0];
                $line     = $matches[0][1];
                $end_line = $matches[0][2];
            } else {
                $proc->msg("Expecting a line number or function; got ${args[0]}");
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
        my $cop = 0;
        $cop = 0 + $DB::dbline[$line];
        $m = sprintf "COP address: 0x%x.", $cop;
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
