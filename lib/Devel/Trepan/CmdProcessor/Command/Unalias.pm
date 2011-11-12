# -*- coding: utf-8 -*-
# Copyright (C) 2011 Rocky Bernstein <rocky@cpan.org>

use warnings; no warnings 'redefine';
use rlib '../../../..';

package Devel::Trepan::CmdProcessor::Command::Unalias;
use if !defined @ISA, Devel::Trepan::CmdProcessor::Command ;
use strict; use vars qw(@ISA); @ISA = @CMD_ISA;
use vars @CMD_VARS;  # Value inherited from parent

our $NAME = set_name();
our $HELP = <<"HELP";
unalias ALIAS

Remove alias ALIAS

See also 'alias'.
HELP

use constant CATEGORY   => 'support';
use constant SHORT_HELP => 'Remove an alias';
our $ARGS  = 1;
  
sub complete($$)
{
    my ($self, $prefix) = @_;
    my $proc = $self->{proc};
    my @candidates = keys %{$proc->{aliases}};
    my @matches = 
	Devel::Trepan::Complete::complete_token(\@candidates, $prefix);
    sort @matches;
}    

# Run command. 
sub run($$) {
    my ($self, $args) = @_;
    my $proc = $self->{proc};
    my @args = @$args; shift @args;
    for my $arg (@args) {
	if (exists $proc->{aliases}{$arg}) {
	    delete $proc->{aliases}{$arg};
	    $proc->msg("Alias for ${arg} removed.");
	} else {
	    $proc->msg("No alias found for ${arg}.");
	}
    }
}

unless (caller) {
    # Demo it.
    require Devel::Trepan::CmdProcessor::Mock;
    my $proc = Devel::Trepan::CmdProcessor::Mock::setup();
    my $cmd = __PACKAGE__->new($proc);
    $cmd->run([$NAME, 's']);
    $cmd->run([$NAME, 's']);
}

1;
