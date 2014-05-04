# -*- coding: utf-8 -*-
# Copyright (C) 2011-2014 Rocky Bernstein <rocky@cpan.org>
use warnings; no warnings 'redefine';
use rlib '../../../..';

package Devel::Trepan::CmdProcessor::Command::Delete;
use English qw( -no_match_vars );

use if !@ISA, Devel::Trepan::CmdProcessor::Command ;

unless (@ISA) {
    eval <<"EOE";
use constant ALIASES    => qw(d);
use constant CATEGORY   => 'breakpoints';
use constant SHORT_HELP => 'Delete some breakpoints';
use constant MIN_ARGS  => 0;  # Need at least this many
use constant MAX_ARGS  => undef;  # Need at most this many - undef -> unlimited.
use constant NEED_STACK => 0;
EOE
}

use strict; use vars qw(@ISA); @ISA = @CMD_ISA;
use vars @CMD_VARS;  # Value inherited from parent

our $NAME = set_name();
our $HELP = <<'HELP';
=pod

B<delete> [I<bp-number> [I<bp-number>...]]

Delete some breakpoints.

Arguments are breakpoint numbers with spaces in between.  To delete
all breakpoints, give no arguments.

See also the C<clear> command which clears breakpoints by line number
and C<info break> to get a list of breakpoint numbers.

=head2 Examples:

    delete 1  # delete breakpoint number 1

=head2 See also:

L<C<break>|Devel::Trepan::CmdProcessor::Command::Break>,
L<C<enable>|Devel::Trepan::CmdProcessor::Command::Enable>, and
L<C<disable>|Devel::Trepan::CmdProcessor::Command::Disable>.

=cut
HELP

# This method runs the command
sub run($$) {
    my ($self, $args) = @_;
    my $proc = $self->{proc};
    my @args = @$args;

    if (scalar @args == 1) {
        if ($proc->confirm('Delete all breakpoints?', 0)) {
            $proc->{brkpts}->reset;
            return;
        }
    }
    shift @args;
    for my $num_str (@args) {
        my $bp_num = $proc->get_an_int($num_str);
        my $success = $proc->{brkpts}->delete($bp_num) if $bp_num;
        $proc->msg("Deleted breakpoint $bp_num") if $success;
    }
}

unless (caller) {
    require Devel::Trepan::CmdProcessor::Mock;
    my $proc = Devel::Trepan::CmdProcessor::Mock::setup();
    # my $cmd = __PACKAGE__->new($proc);
    # $cmd->run([$NAME]);
}

1;
