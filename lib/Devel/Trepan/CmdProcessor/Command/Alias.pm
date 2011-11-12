# -*- coding: utf-8 -*-
# Copyright (C) 2011 Rocky Bernstein <rocky@cpan.org>

use warnings; no warnings 'redefine';
use rlib '../../../..';

package Devel::Trepan::CmdProcessor::Command::Alias;
use if !defined @ISA, Devel::Trepan::CmdProcessor::Command ;
use strict; use vars qw(@ISA); @ISA = @CMD_ISA;
use vars @CMD_VARS;  # Value inherited from parent

our $NAME = set_name();
our $HELP = <<"HELP";
${NAME} ALIAS COMMAND

Add alias ALIAS for a debugger command COMMAND.  

Add an alias when you want to use a command abbreviation for a command
that would otherwise be ambigous. For example, by default we make 's'
be an alias of 'step' to force it to be used. Without the alias, "s"
might be "step", "show", or "set" among others

Example:

alias cat list   # "cat rubyfile.rb" is the same as "list rubyfile.rb"
alias s   step   # "s" is now an alias for "step".
                 # The above examples done by default.

See also 'unalias' and 'show ${NAME}'.
HELP

use constant CATEGORY   => 'support';
use constant SHORT_HELP => 'Add an alias for a debugger command';
  
# Run command. 
sub run($$) {
    my ($self, $args) = @_;
    my $proc = $self->{proc};
    if (scalar @$args == 1) {
	$proc->{commands}->{show}->run(['show', ${NAME}]);
    } elsif (scalar @$args == 2) {
	$proc->{commands}->{show}->run(['show', ${NAME}, $args->[1]]);
    } else {
	my ($junk, $al, $command) = @$args;
	my $old_command = $proc->{aliases}{$al};
	if (exists $proc->{commands}{$command}) {
	    $proc->{aliases}{$al} = $command;
	    if ($old_command) {
		$self->msg("Alias '${al}' for command '${command}' replaced old " .
			   "alias for '${old_command}'.");
	    } else {
		$self->msg("New alias '${al}' for command '${command}' created.");
	    }
	} else {
	    $self->errmsg("You must alias to a command name, and '${command}' isn't one.");
	}
    }
}

unless (caller) {
    # Demo it.
    require Devel::Trepan::CmdProcessor::Mock;
    my $proc = Devel::Trepan::CmdProcessor::Mock::setup();
    my $cmd = __PACKAGE__->new($proc);
    $cmd->run([$NAME, 'yy', 'foo']);
    $cmd->run([$NAME, 'yy', 'step']);
    $cmd->run([$NAME]);
    $cmd->run([$NAME, 'yy', 'next']);
}

1;
