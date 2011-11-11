# -*- coding: utf-8 -*-
# Copyright (C) 2011 Rocky Bernstein <rocky@cpan.org>
use warnings; no warnings 'redefine';
use relative_lib '../../../..';

package Devel::Trepan::CmdProcessor::Command::Watch;
use English qw( -no_match_vars );

use if !defined @ISA, Devel::Trepan::WatchMgr ;
use if !defined @ISA, Devel::Trepan::Condition ;
use if !defined @ISA, Devel::Trepan::CmdProcessor::Command ;

unless (defined @ISA) {
#   eval "use constant ALIASES    => qw(w);";
    eval "use constant CATEGORY   => 'data';";
    eval "use constant NEED_STACK => 0;";
    eval "use constant SHORT_HELP => 
         'Set to enter debugger when a watched expression changes';"
}

use strict; use vars qw(@ISA); @ISA = @CMD_ISA;
use vars @CMD_VARS;  # Value inherited from parent
our $MIN_ARGS   = 1;      # Need at least this many
our $MAX_ARGS   = undef;  # Need at most this many - undef -> unlimited.

our $NAME = set_name();
our $HELP = <<"HELP";
${NAME} PERL-EXPRESSION
 
Stop very time PERL-EXPRESSION changes from its prior value

Examples:
   ${NAME} join(', ', @ARGV)

See also "delete", "enable", and "disable".
HELP

# This method runs the command
sub run($$) {
    my ($self, $args) = @_;
    my $proc = $self->{proc};
    my $expression;
    my @args = @{$args};
    shift @args;

    $expression = join(' ', @args);
    unless (is_valid_condition($expression)) {
	$proc->errmsg("Invalid watch expression: $expression");
	return
    }
    my $wp = $proc->{dbgr}->{watch}->add($expression);
    if ($wp) {
	my $mess = sprintf("Watch expression %d set", $wp->id);
	$proc->msg($mess);
    }
}

unless (caller) {
    require Devel::Trepan::CmdProcessor::Mock;
    my $proc = Devel::Trepan::CmdProcessor::Mock::setup();
    # my $cmd = __PACKAGE__->new($proc);
    # $cmd->run([$NAME]);
}

1;
