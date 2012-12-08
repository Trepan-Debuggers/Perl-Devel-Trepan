# -*- coding: utf-8 -*-
# Copyright (C) 2012 Rocky Bernstein <rocky@cpan.org>
use warnings; no warnings 'redefine'; no warnings 'once';
use rlib '../../../..';

package Devel::Trepan::BWProcessor::Command::Info_Line;
use if !@ISA, Devel::Trepan::BWProcessor::Command ;

use strict;
use vars qw(@ISA); @ISA = @CMD_ISA; 
use vars @CMD_VARS;  # Value inherited from parent
our $NAME = set_name();

# This method runs the command
sub run($$)
{
    my ($self, $arg) = @_;
    my $proc      = $self->{proc};
    my $frame     = $proc->{frame};
    my $filename  = $proc->filename();
    my ($line, $end_line);
    
    if (!$arg->{line}) {
        $line = $frame->{line};
    } else {
        $line = $arg->{line};
    }
    my $fn_name;
    if ($arg->{function}) {
        
        $fn_name = $arg->{function};
        my @matches = $proc->{dbgr}->subs($fn_name);
        unless (scalar(@matches)) {
            # Try with current package name
            $fn_name = $proc->{frame}{pkg} . '::' . $fn_name;
            @matches = $proc->{dbgr}->subs($fn_name);
        }
        if (scalar(@matches) == 1) {
            $filename = $matches[0][0];
            $line     = $matches[0][1];
            $end_line = $matches[0][2];
        } elsif (scalar(@matches) == 0) {
            $proc->msg("Can't find a function match for $fn_name");
            return;
        } else {
            $proc->msg("Multiple function matches for $fn_name");
            return;
        }
    }
    my $loc = {
        canonic_filename => $proc->canonic_file($filename),
        filename         => $filename,
        line_number      => $line
    };
    if (defined $end_line) {
        $loc->{end_line} = $end_line;
        $loc->{function} = $arg->{function};
    }
    local(*DB::dbline) = "::_<$filename";
    if (defined($DB::dbline[$line]) && 0 != $DB::dbline[$line]) {
        my $cop = 0;
        $cop = 0 + $DB::dbline[$line];
        $loc->{op_addr} = $cop;
    } else {
        $proc->msg("Line $line not showing as associated with code")
	    unless defined($end_line);
    }
    $proc->{response}{location} = $loc;
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
1;
