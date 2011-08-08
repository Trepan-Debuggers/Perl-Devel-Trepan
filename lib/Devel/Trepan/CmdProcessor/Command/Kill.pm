# Copyright (C) 2011 Rocky Bernstein <rocky@cpan.org>
# -*- coding: utf-8 -*-
use warnings; no warnings 'redefine';
use lib '../../../..';
# use '../../app/complete'

package Devel::Trepan::CmdProcessor::Command::Kill;

use if !defined @ISA, Devel::Trepan::CmdProcessor::Command ;

use strict;
use vars qw(@ISA);
@ISA = @CMD_ISA;
use vars @CMD_VARS;  # Value inherited from parent

our $NAME = set_name();
our $HELP = <<"HELP";
$NAME [signal-number|signal-name]

Kill execution of program being debugged.

Equivalent of kill('KILL', \$\$). This is an unmaskable
signal\. When all else fails, e.g. in thread code, use this.

If you are in interactive mode, you are prompted to confirm killing.
However when this command is aliased from a command ending in !, no 
questions are asked.

Examples:

  $NAME  
  $NAME unconditionally
  $NAME KILL # same as above
  $NAME kill # same as above
  $NAME -9   # same as above
  $NAME  9   # same as above
  $NAME! 9   # above, but no questions asked
HELP

use constant ALIASES  => ('kill!');
use constant CATEGORY => 'running';
use constant SHORT_HELP => 'Send this process a POSIX signal';
$MAX_ARGS   = 1;  # Need at most this many
  
# sub complete($$) {
#     my ($self, $prefix) = @_;
#     my $completions = Signal.list.keys + 
# 	Signal.list.values + 
# 	Signal.list.values.map{|i| -i} ;
#     Trepan::Complete->complete_token($completions, $prefix);
# }
    
# This method runs the command
sub run($$) {
    my ($self, $args) = @_;
    my $unconditional = substr($args->[0], -1, 1) eq '!';
    my $sig;
    if (scalar(@$args) > 1) {
	$sig = $args->[1];
	unless ( ($sig =~ /[+-]?\d+/) || $SIG{$sig} ) { 
	    $self->errmsg("Signal name '${sig}' is not a signal I know about.");
	    return;
	}
    } else {
	if ($unconditional || $self->{proc}->confirm('Really quit?', 0)) {
	    $sig = 'KILL';
	} else {
	    $self->msg('Kill not confirmed.');
	    return;
	}
    }
    if (kill(0, $$)) {
	# Force finalization on interface.
	$self->{proc}->{interfaces} = [] if 
	    'KILL' eq $sig || 9 == $sig || -9 == $sig;
	if (kill($sig, $$)) {
	    $self->msg("kill ${sig} successfully sent to process $$");
	} else {
	    $self->errmsg("Kill ${sig} to process $$ not accepted: $!")
	}
    } else {
	$self->errmsg(["Unable kill ${sig} to process $$",
		       "Different uid and not super-user?"]);
    }
}

unless (caller()) {
    require Devel::Trepan::CmdProcessor::Mock;
    my $proc = Devel::Trepan::CmdProcessor::Mock::setup();
    my $cmd = Devel::Trepan::CmdProcessor::Command::Kill->new($proc);
    print $cmd->{help}, "\n";
    print join(', ', @{$cmd->{aliases}}), "\n";
    print "min args: ", eval('$' . __PACKAGE__ . "::MIN_ARGS"), "\n";
    for my $arg (qw(fooo 100 1 -1 HUP -9)) {
      print "$NAME ${arg}\n";
      $cmd->run([$NAME, $arg]);
      my $sep = '=' x 40 . "\n";
      print $sep;
    }
}

1;
