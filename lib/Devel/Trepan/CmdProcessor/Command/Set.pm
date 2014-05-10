# -*- coding: utf-8 -*-
# Copyright (C) 2011-2014 Rocky Bernstein <rocky@cpan.org>
use warnings; no warnings 'redefine';

package Devel::Trepan::CmdProcessor::Command::Set;

use rlib '../../../..';
use if !@ISA, Devel::Trepan::CmdProcessor::Command::Subcmd::SubMgr;
unless (@ISA) {
    eval <<'EOE';
    use constant CATEGORY => 'support';
    use constant SHORT_HELP => 'Modify parts of the debugger environment';
    use constant MIN_ARGS   => 0;     # Need at least this many
    use constant MAX_ARGS   => undef; # Need at most this many -
                                      # undef -> unlimited.
    use constant NEED_STACK => 0;
EOE
}

use if !@ISA, Devel::Trepan::CmdProcessor::Command;
use strict;
use vars qw(@ISA);
@ISA = qw(Devel::Trepan::CmdProcessor::Command::SubcmdMgr);
use vars @CMD_VARS;

our $NAME = set_name();
=pod

=head2 Synopsis:

=cut

our $HELP = <<'HELP';
=pod

B<set> [I<set sub-commmand> ...]

Modifies parts of the debugger environment.

You can give unique prefix of the name of a subcommand to get
information about just that subcommand.

Type C<set> for a list of set subcommands and what they do.

Type C<help set *> for the list of C<set> subcommands.

C<set auto...> is the same as C<set auto ...>. For example, C<set
autolist> is the same as L<C<set auto
list>|Devel::Trepan::CmdProcessor::Command::Set::Auto::List>.

=head2 See also:

L<C<set abbrev>|Devel::Trepan::CmdProcessor::Command::Set::Abbrev>,
L<C<set auto>|Devel::Trepan::CmdProcessor::Command::Set::Auto>,
L<C<set basename>|Devel::Trepan::CmdProcessor::Command::Set::Basename>,
L<C<set confirm>|Devel::Trepan::CmdProcessor::Command::Set::Confirm>,
L<C<set debug>|Devel::Trepan::CmdProcessor::Command::Set::Debug>,
L<C<set different>|Devel::Trepan::CmdProcessor::Command::Set::Different>,
L<C<set display>|Devel::Trepan::CmdProcessor::Command::Set::Display>,
L<C<set highlight>|Devel::Trepan::CmdProcessor::Command::Set::Highlight>,
L<C<set max>|Devel::Trepan::CmdProcessor::Command::Set::Max>,
L<C<set return>|Devel::Trepan::CmdProcessor::Command::Set::Return>,
L<C<set substitute>|Devel::Trepan::CmdProcessor::Command::Set::Substitute>,
L<C<set timer>|Devel::Trepan::CmdProcessor::Command::Set::Timer>,
L<C<set trace>|Devel::Trepan::CmdProcessor::Command::Set::Trace>, and
L<C<set variable>|Devel::Trepan::CmdProcessor::Command::Set::Variable>
=cut
HELP

sub run($$)
{
    my ($self, $args) = @_;
    my $first;
    if (scalar @$args > 1) {
        $first = lc $args->[1];
        my $alen = length('auto');
        splice(@$args, 1, 1, ('auto', substr($first, $alen))) if
            index($first, 'auto') == 0 && length($first) > $alen;
    }
    $self->SUPER::run($args);
}

unless (caller) {
    require Devel::Trepan::CmdProcessor;
    my $proc = Devel::Trepan::CmdProcessor->new(undef, 'bogus');
    my $cmd = __PACKAGE__->new($proc, $NAME);
    # require_relative '../mock'
    $cmd->run([$NAME]);
    # $cmd->run([$NAME, 'autolist']);
    # $cmd->run([$NAME, 'autoeval', 'off']);
    $cmd->run([$NAME, 'basename']);
}

1;
