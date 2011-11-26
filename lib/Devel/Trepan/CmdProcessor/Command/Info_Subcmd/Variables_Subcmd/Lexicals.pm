# -*- coding: utf-8 -*-
# Copyright (C) 2011 Rocky Bernstein <rocky@cpan.org>
use warnings; no warnings 'redefine'; no warnings 'once';
use rlib '../../../../../..';

package Devel::Trepan::CmdProcessor::Command::Info::Variables::Lexicals;
our (@ISA, @SUBCMD_VARS);

use Devel::Trepan::CmdProcessor::Command::Subcmd::Subsubcmd;
use PadWalker qw(peek_my peek_our);
use Devel::Trepan::CmdProcessor::Command::Info_Subcmd::Variables_Subcmd::My;

our $CMD = "info variables lexicals";
my  @CMD = split(/ /, $CMD);
use constant MAX_ARGS => undef;
our $MIN_ABBREV = length('l');
our $HELP   = <<"HELP";
${CMD}
${CMD} -v
${CMD} VAR1 [VAR2...]

Lists 'my' or 'lexical' variables at the current frame. Use the frame changing
commands like 'up', 'down' or 'frame' set the current frame.

In the first form, give a list of 'my' or 'our' variable names only. 
In the second form, list variable names and values
In the third form, list variable names and values of VAR1, etc.

See also 'set variable', and frame changing commands
HELP
our $SHORT_HELP   = "Information about 'my' or 'our' variables.";

@ISA = qw(Devel::Trepan::CmdProcessor::Command::Info::Variables::My);

sub run($$)
{
    my ($self, $args) = @_;
    # FIXME: combine with My.pm
    my $i = 0;
    while (my ($pkg, $file, $line, $fn) = caller($i++)) { ; };
    my $diff = $i - $DB::stack_depth;

    # FIXME: 4 is a magic fixup constant, also found in DB::finish.
    # Remove it.
    my $my_hash  = peek_my($diff + $self->{proc}->{frame_index} + 4);
    my $our_hash = peek_our($diff + $self->{proc}->{frame_index} + 4);

    my @ARGS = @{$args};
    @ARGS = splice(@ARGS, scalar(@CMD));
    if (scalar(@ARGS == 0)) {
	$self->process_args(\@ARGS, $my_hash, 'my');
	$self->process_args(\@ARGS, $our_hash, 'our');
    } else {
	if ($ARGS[0] eq '-v') {
	    $self->process_args(['-v'], $my_hash, 'my');
	    $self->process_args(['-v'], $our_hash, 'our');
	} else {
	    my $proc = $self->{proc};
	    for my $name (@ARGS) {
		if (exists($my_hash->{$name})) {
		    Devel::Trepan::CmdProcessor::Command::Info::Variables::My::show_var($proc, $name, $my_hash->{$name});
		} elsif (exists($our_hash->{$name})) {
		    Devel::Trepan::CmdProcessor::Command::Info::Variables::My::show_var($proc, $name, $our_hash->{$name});
		} else {
		    $proc->errmsg("No 'my' or 'our' variable $name found at this level");
		}
	    }
	}
    }
}

unless (caller) { 
    # Demo it.

}

1;
