# -*- coding: utf-8 -*-
# Copyright (C) 2012, 2014-2015 Rocky Bernstein <rocky@cpan.org>
use warnings; no warnings 'redefine'; no warnings 'once';
use rlib '../../../../../..';

package Devel::Trepan::CmdProcessor::Command::Show::Display::OP;
use Devel::Trepan::CmdProcessor::Command::Subcmd::Subsubcmd;

use strict;
use vars qw(@ISA @SUBCMD_VARS);
@ISA = qw(Devel::Trepan::CmdProcessor::Command::ShowBoolSubsubcmd);
# Values inherited from parent

use vars @Devel::Trepan::CmdProcessor::Command::Subsubcmd::SUBCMD_VARS;

our $IN_LIST      = 1;
use constant MAX_ARGS => 0;
our $HELP         = <<'HELP';
=pod

Show OP address in debugger location.

Showing the OP address allows you to disambiguate
I<exactly> where you are in a line that may have many statements or
stopping points.

=head2 See also:

L<C<set display op>|Devel::Trepan::CmdProcessor::Command::Set::Display::Eval>,, C<show line>, C<show program> and
C<disassemble> via plugin L<Devel::Trepan::Disassemble>
=cut
HELP

our $MIN_ABBREV   = length('op');
our $SHORT_HELP   = "Show OP address setting";

unless (caller) {
    # Demo it.
    # DRY this.
    require Devel::Trepan::CmdProcessor;
    my $cmdproc = Devel::Trepan::CmdProcessor->new();
    my $subcmd  =  Devel::Trepan::CmdProcessor::Command::Show->new($cmdproc, 'show');
    my $dispcmd =  Devel::Trepan::CmdProcessor::Command::Show::Display->new($subcmd, 'display');
    my $cmd   =  Devel::Trepan::CmdProcessor::Command::Show::Display::OP->new($dispcmd, 'op');
    # Add common routine
    foreach my $field (qw(min_abbrev name)) {
	printf "Field %s is: %s\n", $field, $cmd->{$field};
    }
    $cmd->run();
}

1;
