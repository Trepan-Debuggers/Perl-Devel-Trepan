# -*- coding: utf-8 -*-
# Copyright (C) 2011-2014 Rocky Bernstein <rocky@cpan.org>

use warnings; no warnings 'redefine';
use rlib '../../../..';

package Devel::Trepan::CmdProcessor::Command::Macro;
use English qw( -no_match_vars );
use if !@ISA, Devel::Trepan::CmdProcessor::Command ;
unless (@ISA) {
    eval <<'EOE';
use constant CATEGORY   => 'support';
use constant SHORT_HELP => 'Define a macro';
use constant MIN_ARGS   => 3; # Need at least this many
use constant MAX_ARGS   => undef; # Need at most this many - undef -> unlimited.
EOE
}

use strict; use vars qw(@ISA); @ISA = @CMD_ISA;
use vars @CMD_VARS;  # Value inherited from parent

our $NAME = set_name();
=pod

=head2 Synopsis:

=cut
our $HELP = <<'HELP';
=pod

macro I<macro-name> sub { ... }

Define I<macro-name> as a debugger macro. Debugger macros get a list of
arguments which you supply without parenthesis or commas. See below
for an example.

The macro (really a Perl anonymous subroutine) should return either a
string or an list reference to a list of strings. Each string is a
debugger command.

If a single string is returned, that gets tokenized by a simple C<split(/ /,
$string)>.  Note that macro processing is done right after splitting
on C<;;> so if the macro returns a string containing C<;;> this will
not be handled on the string returned.

If a reference to a list of strings is returned instead, then the
first string is shifted from the array and executed. The remaining
strings are pushed onto the command queue. In contrast to the first
string, subsequent strings can contain other macros. Any C<;;> in those
strings will be split into separate commands.

=head2 Examples:

The below creates a macro called I<fin+> which issues two commands
C<finish> followed by C<step>:

 macro fin+ sub{ ['finish', 'step']}

If you wanted to parameterize the argument of the C<finish> command
you could do it this way:

  macro fin+ sub{ \
                  ['finish', 'step ' . (shift)] \
                }

Invoking with:

  fin+ 3

would expand to C<["finish", "step 3"]>

If you were to add another parameter, note that the invocation is like
you use for other debugger commands, no commas or parenthesis. That is:

 fin+ 3 2

rather than C<fin+(3,2)> or C<fin+ 3, 2>.

=head2 See also:

L<C<alias>|Devel::Trepan::CmdProcessor::Command::Alias>, and
L<C<info macro>|Devel::Trepan::CmdProcessor::Command::Info::Macro>.

=cut
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
    require Devel::Trepan::CmdProcessor;
    my $proc = Devel::Trepan::CmdProcessor->new(undef, 'bogus');
    my $cmd = __PACKAGE__->new($proc);
    $proc->{cmd_argstr} = "fin+ sub{ ['finish', 'step']}";
    my @args = ($NAME, split(/\s+/, $proc->{cmd_argstr}));
    $cmd->run(\@args);
    print join(' ', @{$proc->{macros}{'fin+'}}), "\n";
}

1;
