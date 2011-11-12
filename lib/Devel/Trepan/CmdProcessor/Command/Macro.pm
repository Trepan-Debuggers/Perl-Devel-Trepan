# -*- coding: utf-8 -*-
# Copyright (C) 2011 Rocky Bernstein <rocky@cpan.org>

use warnings; no warnings 'redefine';
use rlib '../../../..';

package Devel::Trepan::CmdProcessor::Command::Macro;
use English qw( -no_match_vars );
use if !defined @ISA, Devel::Trepan::CmdProcessor::Command ;
unless (defined(@ISA)) {
    eval "use constant CATEGORY   => 'support';";
    eval "use constant SHORT_HELP => 'Define a macro';";
}

use strict; use vars qw(@ISA); @ISA = @CMD_ISA;
use vars @CMD_VARS;  # Value inherited from parent

our $MIN_ARGS = 3;
our $MAX_ARGS = undef;
our $NAME = set_name();
our $HELP = <<"HELP";
${NAME} MACRO-NAME sub { ... }

Define MACRO-NAME as a debugger macro. Debugger macros get a list of
arguments which you supply without parenthesis or commas. See below
for an example.

The macro (really a Perl anonymous subroutine) should return either a
string or an array reference to a list of strings. The string in both
cases are strings of debugger commands.  If the return is a string,
that gets tokenized by a simple split(/ /, \$string).  Note that macro
processing is done right after splitting on ;; so if the macro returns
a string containing ;; this will not be handled on the string
returned.

If instead, a reference to a list of strings is returned, then the
first string is shifted from the array and executed. The remaining
strings are pushed onto the command queue. In contrast to the first
string, subsequent strings can contain other macros. Any ;; in those
strings will be split into separate commands.

Here is an example. The below creates a macro called fin+ which
issues two commands 'finish' followed by 'step':

  macro fin+ sub{ ['finish', 'step']}

If you wanted to parameterize the argument of the 'finish' command
you could do that this way:

  macro fin+ sub{ ['finish ' . shift, 'step']}

Invoking with 
  fin+ 3

would expand to ["finish 3", "step"]

If you were to add another parameter for 'step', the note that the 
invocation might be 
  fin+ 3 2

rather than 'fin+(3,2)' or 'fin+ 3, 2'.

See also 'info macro'.
HELP
  
# This method runs the command
sub run($$) {
    my ($self, $args) = @_;
    my $cmd_name = $args->[1];
    my $proc = $self->{proc};
    my $cmd_argstr = $proc->{cmd_argstr};
    $cmd_argstr =~ s/^\s+//;
    $cmd_argstr = substr($cmd_argstr, length($cmd_name));
    $cmd_argstr =~ s/^\s+//;
    my $fn = eval($cmd_argstr);
    if ($EVAL_ERROR) { 
	$proc->errmsg($EVAL_ERROR)
    } elsif ($fn && ref($fn) eq 'CODE') {
        $proc->{macros}{$cmd_name} = [$fn, $cmd_argstr];
	$proc->msg("Macro \"${cmd_name}\" defined.");
    } else {
	$proc->errmsg("Expecting an anonymous subroutine");
    }
}
        
unless (caller) {
    require Devel::Trepan::CmdProcessor::Mock;
    my $cmdproc = Devel::Trepan::CmdProcessor::Mock::setup();
    # for my $cmdline  ("${cmd.name} foo Proc.new{|x, y| 'x+y'}",
    # 		      "#{cmd.name} bad2 1+2") {
    # 	@args = split $cmdline;
    # 	$cmd_argstr = cmdline[args[0].size..-1].lstrip;
    # 	$cmdproc->instance_variable_set('@cmd_argstr', $cmd_argstr);
    # 	$cmd->run(@args);
    # }
    # print $cmdproc->{macros};
}

1;
