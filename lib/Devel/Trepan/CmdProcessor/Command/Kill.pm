# Copyright (C) 2011 Rocky Bernstein <rocky@cpan.org>
# -*- coding: utf-8 -*-
use feature ":5.10";  # Includes "state" feature.
use warnings; no warnings 'redefine';
use rlib '../../../..';
# use '../../app/complete'

package Devel::Trepan::CmdProcessor::Command::Kill;

use if !defined @ISA, Devel::Trepan::CmdProcessor::Command ;

use vars qw(@ISA);

unless (defined @ISA) {
    eval "use constant ALIASES  => ('kill!')";
    eval "use constant CATEGORY => 'running'";
    eval "use constant SHORT_HELP => 'Send this process a POSIX signal'";
}
use strict; 

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

$MAX_ARGS   = 1;  # Need at most this many
  
sub complete($$) {
    my ($self, $prefix) = @_;
    state @completions;
    unless(@completions) {
	@completions = keys %SIG;
	my $last_sig = scalar @completions;
	push @completions, map({lc $_} @completions);
	my @nums = (-$last_sig .. $last_sig);
	push @completions, @nums;
	push @completions, 'unconditionally';
    }
    my @matches = 
	Devel::Trepan::Complete::complete_token(\@completions, $prefix);
    sort @matches;
}
    
# This method runs the command
sub run($$) {
    my ($self, $args) = @_;
    my $unconditional = substr($args->[0], -1, 1) eq '!';
    my $sig;
    if (scalar(@$args) > 1) {
	$sig = uc($args->[1]);
	unless ( ($sig =~ /[+-]?\d+/) || exists $SIG{$sig} ) { 
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
	$self->{proc}{interfaces} = [] if 
	    'KILL' eq $sig || 9 eq $sig || -9 eq $sig;
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
    require Devel::Trepan::CmdProcessor;
    my $proc = Devel::Trepan::CmdProcessor->new;
    my $cmd = __PACKAGE__->new($proc);
    print $cmd->{help}, "\n";
    print join(', ', @{$cmd->{aliases}}), "\n";
    print "min args: ", eval('$' . __PACKAGE__ . "::MIN_ARGS"), "\n";
    for my $arg ('hu', 'HU', '', 1, '-9') {
	printf "complete($arg) => %s\n", join(", ", $cmd->complete($arg));
    }
    for my $arg (qw(fooo 100 1 -1 HUP -9)) {
      print "$NAME ${arg}\n";
      $cmd->run([$NAME, $arg]);
      my $sep = '=' x 40 . "\n";
      print $sep;
    }
}

1;
