# -*- coding: utf-8 -*-
# Copyright (C) 2012 Rocky Bernstein <rocky@cpan.org>
use warnings; no warnings 'redefine'; no warnings 'once';
use rlib '../../../..';

package Devel::Trepan::BWProcessor::Command::Info_Line;
=pod

=head1 Info_Line

Line Location for debugged program.

=head2 Input Fields

 { command => 'info_line',
   [fn_name => <function-name>],
   [line    => <line-number>],
 }

If I<line> isn't given, then information is given for the current
line.  If I<line> is not a place where a breakpoint can be given,
you'll get a message to that effect.

If I<function-name> is given, we return the starting and ending lines
of that function. You should not give both a function name and a line
number, although giving neither is okay. If both are given, just the
function name is used.

=head2 Output Fields

 { name       => 'info_line',
   {location   => <location-info> |
    errmsg     => <error-message-array>},
   [end_line  => <last-line-of-function>],
   [msg       => <message-text array>]
 }

Unless there is an error I<location> is set, otherwise
I<errmsg> is set.

=cut

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
    my $fn_name   = $arg->{function};
    my $end_line;

    my $line = $arg->{line} || $frame->{line};
    if ($fn_name) {
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
            $proc->errmsg("Can't find a function match for $fn_name");
            return;
        } else {
            $proc->errmsg("Multiple function matches for $fn_name");
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
        my $cop_addr = (+ $DB::dbline[$line]) if $DB::dbline[$line] ;
        $loc->{op_addr} = $cop_addr if $cop_addr;
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
