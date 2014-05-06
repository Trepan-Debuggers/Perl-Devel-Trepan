# -*- coding: utf-8 -*-
# Copyright (C) 2011-2014 Rocky Bernstein <rocky@cpan.org>
use warnings; no warnings 'redefine';
use rlib '../../../..';

package Devel::Trepan::CmdProcessor::Command::Display;
use English qw( -no_match_vars );

use if !@ISA, Devel::Trepan::DB::Display ;
use if !@ISA, Devel::Trepan::Condition ;
use if !@ISA, Devel::Trepan::CmdProcessor::Command ;

unless (@ISA) {
    eval <<"EOE";
use constant CATEGORY   => 'data';
use constant NEED_STACK => 0;
use constant SHORT_HELP =>
         'Display expressions when entering debugger';
use constant MIN_ARGS  => 1;  # Need at least this many
use constant MAX_ARGS  => undef;  # Need at most this many - undef -> unlimited.
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

B<display> I<Perl-expression>

Print value of expression I<Perl-expression> each time the program stops.

=head2 Examples:

 display $a  # Display variable \$a each time we enter debugger
 display join(', ', @ARGV)  # show values of array @ARGV

If what you want to do is evaluate a Perl expression or statement once
rather than every time the program stops, see C<eval>.

See also C<undisplay>, C<enable>, C<disable>.
=cut
HELP

# This method runs the command
sub run($$) {
    my ($self, $args) = @_;
    my $proc = $self->{proc};
    my $display;
    my @args = @{$args};
    shift @args;

    $display = join(' ', @args);
    unless (is_valid_condition($display)) {
        $proc->errmsg("Invalid display: $display");
        return
    }
    my $disp = $proc->{displays}->add($display);
    if ($disp) {
        my $mess = sprintf("Display %d set", $disp->number);
        $proc->msg($mess);
    }
}

unless (caller) {
    require Devel::Trepan::CmdProcessor::Mock;
    my $proc = Devel::Trepan::CmdProcessor::Mock::setup();
    # my $cmd = __PACKAGE__->new($proc);
    # $cmd->run([$NAME]);
}

1;
