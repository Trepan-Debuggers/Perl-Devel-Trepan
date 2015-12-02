# -*- coding: utf-8 -*-
# Copyright (C) 2015 Rocky Bernstein <rocky@cpan.org>
use warnings; no warnings 'redefine';
use rlib '../../../..';

package Devel::Trepan::CmdProcessor::Command::Clear;
use English qw( -no_match_vars );

use if !@ISA, Devel::Trepan::CmdProcessor::Command ;

unless (@ISA) {
    eval <<"EOE";
use constant ALIASES    => qw(d);
use constant CATEGORY   => 'breakpoints';
use constant SHORT_HELP => 'Clear some breakpoints';
use constant MIN_ARGS  => 0;  # Need at least this many
use constant MAX_ARGS  => undef;  # Need at most this many - undef -> unlimited.
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

B<clear> [I<line-number>]

=head2 See also:

L<C<delete>|Devel::Trepan::CmdProcessor::Command::Delete>,

=cut
HELP

# This method runs the command
sub run($$) {
    my ($self, $args) = @_;
    my $proc = $self->{proc};
    my @args = @$args;
    my $line_number = $proc->{frame}{line};

   if (scalar @args > 1) {
        $line_number = $proc->get_an_int($args->[1]);
	return unless $line_number;
   }

    my $bpmgr = $proc->{brkpts};
    my @brkpts = @{$bpmgr->{list}};
    my @line_nos = ();
    foreach my $bp (@brkpts) {
	if ($bp->line_num == $line_number) {
	    my $bp_num = $bp->id;
	    push @line_nos, $bp_num;
	    $proc->{brkpts}->delete($bp_num);
	}
    }
    my $count = scalar @line_nos;
    if ($count == 0) {
	$self->errmsg(sprintf "No breakpoint at line %d", $line_number);
    } elsif ($count == 1) {
	$self->msg(sprintf "Deleted breakpoint %d", $line_nos[0]);
    } elsif ($count >= 1) {
	$self->msg(sprintf "Deleted breakpoints %s", join(' ', @line_nos));
    }
}

unless (caller) {
    require Devel::Trepan::DB;
    require Devel::Trepan::Core;
    my $db = Devel::Trepan::Core->new;
    my $intf = Devel::Trepan::Interface::User->new(undef, undef, {readline => 0});
    my $proc = Devel::Trepan::CmdProcessor->new([$intf], $db);

    $proc->{stack_size} = 0;
    $proc->{frame} = {line => 1};
    my $cmd = __PACKAGE__->new($proc);
    $cmd->run([$NAME]);
    $cmd->run([$NAME, '5']);
}

1;
