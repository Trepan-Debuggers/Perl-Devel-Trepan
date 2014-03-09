# -*- coding: utf-8 -*-
# Copyright (C) 2012, 2014 Rocky Bernstein <rocky@cpan.org>
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

See also C<set display op>, C<show line>, C<show program> and
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
    my $opcmd   =  Devel::Trepan::CmdProcessor::Command::Show::Display::OP->new($dispcmd, 'op');
    # Add common routine
    foreach my $field (qw(min_abbrev name)) {
	printf "Field %s is: %s\n", $field, $opcmd->{$field};
    }
    $opcmd->run();
}

1;
