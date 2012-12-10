# Copyright (C) 2012 Rocky Bernstein <rocky@cpan.org>
# -*- coding: utf-8 -*-
use warnings; no warnings 'redefine';
use rlib '../../../..';

package Devel::Trepan::BWProcessor::Command::Run;
use English qw( -no_match_vars );

=head1 Run

Hard run of debugged program via exec

=head2 Input Fields

 { command  => 'run',
 }


=head2 Output Fields

 { name           => 'run',
   args           => <array-ref>,
   trepanpl_opts  => <data-dumper-string>,
   [msg           => <array-ref>],
   [errmsg        => <array-ref>]
 }

args contains the arguments passed to Perl. trepanpl_opts is the value of
environment varliable I<TREPANPL_OPTS> which influences how trepan.pl is 
run.

=cut

use if !@ISA, Devel::Trepan::BWProcessor::Command ;

use strict;
use vars qw(@ISA); @ISA = @CMD_ISA;
use vars @CMD_VARS;  # Value inherited from parent

$NAME = set_name();

# This method runs the command
sub run($$) {
    my ($self, $args) = @_;
    my $proc = $self->{proc};
    my $dbgr = $proc->{dbgr};

    # I may not be able to resurrect you, but here goes ...
    $self->msg("Warning: some settings and command-line options may be lost!");

    my @script = $proc->restart_args();

    # $self->msg( "Running: " . join(' ', @script));

    $proc->{response}{args} = \@script;
    $proc->{response}{trepanpl_opts} = $ENV{'TREPANPL_OPTS'};
    $proc->flush_msg;

   # And run Perl again.  We use exec() to keep the
    # PID stable (and that way $ini_pids is still valid).
    exec(@script) || $self->errmsg("exec failed: $!");

}

unless (caller()) {
    # require Devel::Trepan::CmdProcessor::Mock;
    # my $proc = Devel::Trepan::CmdProcessor::Mock::setup();
    # my $cmd = Devel::Trepan::CmdProcessor::Command::Run->new($proc);
}

1;
