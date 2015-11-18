# -*- coding: utf-8 -*-
# Copyright (C) 2012, 2014-2015 Rocky Bernstein <rocky@cpan.org>
use warnings; no warnings 'redefine'; no warnings 'once';
use rlib '../../../../../..';

use Devel::Trepan::DB;

package Devel::Trepan::CmdProcessor::Command::Set::Display::OP;
use Devel::Trepan::CmdProcessor::Command::Subcmd::Subsubcmd;

use strict;
use vars qw(@ISA @SUBCMD_VARS);
@ISA = qw(Devel::Trepan::CmdProcessor::Command::SetBoolSubsubcmd);
# Values inherited from parent

use vars @Devel::Trepan::CmdProcessor::Command::Subsubcmd::SUBCMD_VARS;

our $IN_LIST      = 1;
=pod

=head2 Synopsis:

=cut

our $HELP         = <<'HELP';
=pod

B<set display op>

Set to show the I<OP> address in location status.

The OP address is the address of the Perl opcode tree that is about
to be run. It gives the most precise indication of where you are, and
can be useful in disambiguating where among Perl several
statements in a line you.

In a mult-statement line, the C<deparse> command will print just the
current command.

=head2 See also:

L<C<show display op>|Devel::Trepan::CmdProcessor::Command::Show::Display::OP>,
L<C<deparse>|Devel::Trepan::CmdProcessor::Command::Deparse>,
L<C<info line>|Devel::Trepan::CmdProcessor::Command::Info::Line>,
L<C<info program>|Devel::Trepan::CmdProcessor::Command::Info::Line> and
L<C<disassemble>|Devel::Trepan::CmdProcessor::Command::Disassemble>
(via plugin L<Devel::Trepan::Disassemble>).
=cut

HELP

our $MIN_ABBREV   = length('co');
use constant MAX_ARGS => 1;
our $SHORT_HELP   = "Set to show OP address in locations";

unless (caller) {
    # Demo it.
    # DRY this.
    require Devel::Trepan::CmdProcessor;
    my $cmdproc = Devel::Trepan::CmdProcessor->new();
    my $subcmd  =  Devel::Trepan::CmdProcessor::Command::Set->new($cmdproc, 'set');
    my $parent_cmd =  Devel::Trepan::CmdProcessor::Command::Set::Display->new($subcmd, 'display');
    my $cmd   =  __PACKAGE__->new($parent_cmd, 'op');
    # Add common routine
    foreach my $field (qw(min_abbrev name)) {
	printf "Field %s is: %s\n", $field, $cmd->{$field};
    }
    my @args = qw(set display op on);
    $cmd->run(\@args);
    @args = qw(set display op off);
    $cmd->run(\@args);
}

1;
