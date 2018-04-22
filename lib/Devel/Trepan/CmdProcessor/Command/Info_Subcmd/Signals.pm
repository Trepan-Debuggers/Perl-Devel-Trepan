# -*- coding: utf-8 -*-
# Copyright (C) 2011-2012, 2014, 2016, 2018 Rocky Bernstein <rocky@cpan.org>

use warnings; use strict; use types;
use rlib '../../../../..';

package Devel::Trepan::CmdProcessor::Command::Info::Signals;
require Devel::Trepan::Complete;
use Devel::Trepan::CmdProcessor::Command::Subcmd::Core;

use vars qw(@ISA @SUBCMD_VARS);
@ISA = qw(Devel::Trepan::CmdProcessor::Command::Subcmd);
# Values inherited from parent
use vars @Devel::Trepan::CmdProcessor::Command::Subcmd::SUBCMD_VARS;

unless (@ISA) {
    eval <<"EOE";
use constant MAX_ARGS => undef;  # Need at most this many - undef -> unlimited.
EOE
}

our $CMD = "info signals";
=pod

=head2 Synopsis:

=cut

our $HELP         = <<'HELP';
=pod

B<info signals>

B<info signals> I<signal1> [I<signal2> ..]

In the first form a list of the existing signals and actions are shown.

In the second form, list just the given signals and their definitions
are shown.

Signals can be either their signal name or number. The case is not
significant when giving a signal name. A signal name C<SIG> or
not. For a signal number, you can preface the number with C<+> or
C<->, but both are ignored. A negative number is the same as its
corresponding positive number.

=head2 See also:

L<C<handle>|Devel::Trepan::CmdProcessor::Command::Handle> for descriptions of the settable fields shown.
=cut
HELP

our $MIN_ABBREV = length('sig');
our $SHORT_HELP = 'What debugger does when program gets various signals';

no warnings 'redefine';
sub complete($self, $prefix) {
    my @matches =Devel::Trepan::Complete::signal_complete($prefix);
    return sort @matches;
}

sub run($self, $args) {
    my $proc = $self->{proc};
    my @args = splice(@$args, 2);
    $proc->{dbgr}{sigmgr}->info_signal(\@args);
}

unless(caller) {
    # Demo it.
    require Devel::Trepan::CmdProcessor;
    my $proc = Devel::Trepan::CmdProcessor->new;
    my $parent = Devel::Trepan::CmdProcessor::Command::Info->new($proc, 'info');
    my $cmd = __PACKAGE__->new($parent, 'signals');

    print $cmd->{help}, "\n";
    print "min args: ", $cmd->MIN_ARGS, "\n";
}

1;
