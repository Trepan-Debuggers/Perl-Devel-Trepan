# -*- coding: utf-8 -*-
# Copyright (C) 2011-2012, 2014 Rocky Bernstein <rocky@cpan.org>

use warnings; no warnings 'redefine';
use rlib '../../../..';

package Devel::Trepan::CmdProcessor::Command::Unalias;
use if !@ISA, Devel::Trepan::CmdProcessor::Command ;

unless (@ISA) {
    eval <<'EOE';
use constant CATEGORY   => 'support';
use constant SHORT_HELP => 'Remove an alias';
use constant MIN_ARGS   => 0;     # Need at least this many
use constant MAX_ARGS   => undef; # Need at most this many - undef -> unlimited.
use constant NEED_STACK => 0;
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

B<unalias> I<alias1> [I<alias2> ...]

Remove alias I<alias1> and so on.

=head2 Example:

 unalias s  # Remove 's' as an alias for 'step'

=head2 See also:

L<C<alias>|Devel::Trepan::CmdProcessor::Command::Alias>, and
L<C<show aliases>|Devel::Trepan::CmdProcessor::Command::Show::Aliases>.

=cut
HELP

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
            my $command_name = $proc->{aliases}{$arg};
            $proc->remove_alias($command_name, $arg);
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
