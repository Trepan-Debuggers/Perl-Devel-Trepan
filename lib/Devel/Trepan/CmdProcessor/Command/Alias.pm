# -*- coding: utf-8 -*-
# Copyright (C) 2011-2012, 2014 Rocky Bernstein <rocky@cpan.org>

use warnings; no warnings 'redefine';
use rlib '../../../..';

package Devel::Trepan::CmdProcessor::Command::Alias;
use if !@ISA, Devel::Trepan::CmdProcessor::Command ;

unless (@ISA) {
    eval <<"EOE";
use constant CATEGORY   => 'support';
use constant SHORT_HELP => 'Add an alias for a debugger command';
use constant MIN_ARGS  => 0;      # Need at least this many
use constant MAX_ARGS  => undef;  # Need at most this many - undef -> unlimited.
EOE
}


use strict; use vars qw(@ISA); @ISA = @CMD_ISA;
use vars @CMD_VARS;  # Value inherited from parent

our $NAME = set_name();
our $HELP = <<'HELP';
=pod

B<alias> I<alias> I<command>

Add alias I<alias> for a debugger command I<command>.

Add an alias when you want to use a command abbreviation for a command
that would otherwise be ambigous. For example, by default we make C<s>
be an alias of C<step> to force it to be used. Without the alias, C<s>
might be C<step>, C<show>, or C<set>, among others.

=head2 Examples:

 alias cat list   # "cat file.pl" is the same as "list file.pl"
 alias s   step   # "s" is now an alias for "step".
                  # The above "s" alias is initially set up, by
                  # default. But you can change or remove it.

=head2 See also:

L<C<macro>|Devel::Trepan::CmdProcessor::Command::Macro> E<mdash> more complex definitions,
L<C<unalias>|Devel::Trepan::CmdProcessor::Command::Unalias>
L<C<show alias>|Devel::Trepan::CmdProcessor::Command::Show::Alias>

=cut
HELP

# Run command.
sub run($$) {
    my ($self, $args) = @_;
    my $proc = $self->{proc};
    if (scalar @$args == 1) {
        $proc->{commands}->{show}->run(['show', ${NAME}]);
    } elsif (scalar @$args == 2) {
        $proc->{commands}->{show}->run(['show', ${NAME}, $args->[1]]);
    } else {
        my ($junk, $al, $command, @rest) = @$args;
        my $old_command = $proc->{aliases}{$al};
        if (exists $proc->{commands}{$command}) {
            my $cmd_str = join(' ', ($command, @rest));
            $proc->add_alias($command, $al, $cmd_str);
            if ($old_command) {
                $proc->remove_alias($old_command);
                $self->msg("Alias '${al}' for command string '${cmd_str}' replaced old " .
                           "alias for '${old_command}'.");
            } else {
                $self->msg("New alias '${al}' for command string '${cmd_str}' created.");
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
    $cmd->run([$NAME, 'evd', 'show', 'evaldisplay']);
}

1;
