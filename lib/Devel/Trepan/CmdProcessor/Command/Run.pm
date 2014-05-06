# Copyright (C) 2011-2012, 2014 Rocky Bernstein <rocky@cpan.org>
# -*- coding: utf-8 -*-
use warnings; no warnings 'redefine';
use rlib '../../../..';

package Devel::Trepan::CmdProcessor::Command::Run;
use English qw( -no_match_vars );

use if !@ISA, Devel::Trepan::CmdProcessor::Command ;
unless (@ISA) {
    eval <<'EOE';
use constant ALIASES    => ('R', 'restart');
use constant CATEGORY   => 'running';;
use constant SHORT_HELP => '(Hard) restart of program via exec()';
use constant MIN_ARGS   => 0;     # Need at least this many
use constant MAX_ARGS   => undef; # Need at most this many - undef -> unlimited.
EOE
}

use strict;
use vars qw(@ISA);
@ISA = @CMD_ISA;
use vars @CMD_VARS;  # Value inherited from parent

our $NAME = set_name();

=pod

=head2 Synopsis:

=cut
our $HELP = <<'HELP';
=pod

B<run>

Restart debugger and program via an I<exec()> call.

Hash reference variable $Devel::Trepan::Core::invoke_opts contains a
hash of options that were used to start the debugger. These are
consulted in figuring out how to restart.

=head2 See also:

L<C<show args>|Devel::Trepan::CmdProcessor::Command:Show::Args> for
the exact invocation that will be used.

=cut
HELP

# This method runs the command
sub run($$) {
    my ($self, $args) = @_;
    my $proc = $self->{proc};
    my $dbgr = $proc->{dbgr};

    # I may not be able to resurrect you, but here goes ...
    $self->msg("Warning: some settings and command-line options may be lost!");

    my @script = $proc->restart_args();

    my $intf = $proc->{interfaces}[-1];
    $intf->save_history($proc->{last_command});

    $self->msg( "Running: " . join(' ', @script));

    # And run Perl again.  We use exec() to keep the
    # PID stable (and that way $ini_pids is still valid).

    exec(@script) || $self->errmsg("exec failed: $!");

}

unless (caller()) {
    require Devel::Trepan::CmdProcessor::Mock;
    my $proc = Devel::Trepan::CmdProcessor::Mock::setup();
    my $cmd = Devel::Trepan::CmdProcessor::Command::Run->new($proc);
}

1;
