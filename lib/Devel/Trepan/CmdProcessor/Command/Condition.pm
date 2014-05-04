# -*- coding: utf-8 -*-
# Copyright (C) 2011-2012 Rocky Bernstein <rocky@cpan.org>
use warnings; no warnings 'redefine';
use rlib '../../../..';

package Devel::Trepan::CmdProcessor::Command::Condition;
use English qw( -no_match_vars );

use if !@ISA, Devel::Trepan::Condition ;
use if !@ISA, Devel::Trepan::CmdProcessor::Command ;

unless (@ISA) {
    eval <<"EOE";
use constant ALIASES    => qw(cond);
use constant CATEGORY   => 'breakpoints';
use constant NEED_STACK => 0;
use constant SHORT_HELP =>
    'Specify a condition on a breakpoint';
use constant MIN_ARGS  => 2;   # Need at least this many
use constant MAX_ARGS  => undef;  # Need at most this many - undef -> unlimited.
EOE
}

use strict; use vars qw(@ISA); @ISA = @CMD_ISA;
use vars @CMD_VARS;  # Value inherited from parent

our $NAME = set_name();
our $HELP = <<'HELP';
=pod

B<condition> I<bp-number> I<Perl-expression>

I<bp-number> is a breakpoint number.  I<Perl-expresion> is a Perl
expression which must evaluate to true before the breakpoint is
honored.  If I<perl-expression> is absent, any existing condition is removed;
i.e., the breakpoint is made unconditional.

=head2 Examples:

 condition 5 x > 10  # Breakpoint 5 now has condition x > 10
 condition 5         # Remove above condition

=head2 See also:

L<C<break>|Devel::Trepan::CmdProcessor::Command::Break>,
L<C<enable>|Devel::Trepan::CmdProcessor::Command::Enable> and
L<C<disable>|Devel::Trepan::CmdProcessor::Command::Disable>.

=cut
HELP

# This method runs the command
sub run($$) {
    my ($self, $args) = @_;
    my $proc = $self->{proc};
    my $bpnum = $proc->get_an_int($args->[1]);
    return unless defined($bpnum);
    my $bp = $proc->{brkpts}->find($bpnum);
    unless ($bp) {
        $proc->errmsg("No breakpoint number $bpnum");
        return;
    }

    my $condition;
    if (scalar @{$args} > 2) {
        my @args = @{$args};
        shift @args; shift @args;
        $condition = join(' ', @args);
        my $msg = &DB::eval_not_ok($condition);
        if ($msg) {
            $proc->errmsg("Invalid condition: $condition");
            chomp $msg;
            $proc->errmsg($msg);
            return
        }
    } else {
        $condition = '1';
        $proc->msg('Breakpoint $bp->id is now unconditional.');
    }
    $bp->condition($condition);
}

unless (caller) {
    require Devel::Trepan::CmdProcessor::Mock;
    my $proc = Devel::Trepan::CmdProcessor::Mock::setup();
    # my $cmd = __PACKAGE__->new($proc);
    # $cmd->run([$NAME]);
}

1;
