# -*- coding: utf-8 -*-
# Copyright (C) 2011-2013 Rocky Bernstein <rocky@cpan.org>
use warnings; no warnings 'redefine';
use rlib '../../../..';

package Devel::Trepan::CmdProcessor::Command::Action;
use English qw( -no_match_vars );

use if !@ISA, Devel::Trepan::Condition ;
use if !@ISA, Devel::Trepan::CmdProcessor::Command ;

unless (@ISA) {
    eval <<"EOE";
use constant ALIASES    => qw(a);
use constant CATEGORY   => 'breakpoints';
use constant NEED_STACK => 0;
use constant MIN_ARGS  => 2;      # Need at least this many
use constant MAX_ARGS  => undef;  # Need at most this many - undef -> unlimited.
use constant SHORT_HELP =>
    'Set an action to be done before the line is executed.';
EOE
}

use strict; use vars qw(@ISA); @ISA = @CMD_ISA;
use vars @CMD_VARS;  # Value inherited from parent

our $NAME = set_name();
our $HELP = <<'HELP';
=pod

B<action> I<position> I<Perl-statement>

Set an action to be done before the line is executed. If line is
C<.>, set an action on the line about to be executed. The sequence
of steps taken by the debugger is:

=over

=item 1. check for a breakpoint at this line

=item 2. print the line if necessary (tracing)

=item 3. do any actions associated with that line

=item 4. prompt user if at a breakpoint or in single-step

=item 5. evaluate line

=back

For example, this will print out the value of C<$foo> every time line
53 is passed:

=head2 Examples:

   action 53 print "DB FOUND $foo\n"

=head2 See also:

<C<help breakpoints>

=cut
HELP

# This method runs the command
sub run($$) {
    my ($self, $args) = @_;
    my $proc = $self->{proc};
    my $frame = $proc->{frame};
    my @args = @$args;
    shift @args;

    my ($filename, $lineno, $fn, $gobble_count, $rest) =
        $proc->parse_position(\@args, 0); # should be: , 1);
    shift @args if $gobble_count-- > 0;
    shift @args if $gobble_count-- > 0;
    # error should have been shown previously

    my $action_expression = join(' ', @args);
    unless (is_valid_condition($action_expression)) {
        $proc->errmsg("Invalid action: $action_expression");
        return
    }
    my $action = $self->{dbgr}->set_action($lineno, $filename,
                                           $action_expression);
    if ($action) {
        my $id = $action->id;
        my $filename = $proc->canonic_file($action->filename);
        my $line_num = $action->line_num;
        $proc->{actions}->add($action);
        $proc->msg("Action $id set in $filename at line $line_num");

    }
}

unless (caller) {
    require Devel::Trepan::CmdProcessor::Mock;
    my $proc = Devel::Trepan::CmdProcessor::Mock::setup();
    # my $cmd = __PACKAGE__->new($proc);
    # $cmd->run([$NAME]);
}

1;
