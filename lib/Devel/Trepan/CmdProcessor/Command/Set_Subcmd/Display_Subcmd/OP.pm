# -*- coding: utf-8 -*-
# Copyright (C) 2012 Rocky Bernstein <rocky@cpan.org>
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
our $HELP         = <<'HELP';
=pod

Set to show the OP address in location status.

The OP address is the address of the Perl Tree Opcode that is about
to be run. It gives the most precise indication of where you are.
This can be useful in disambiguating where among Perl several
statements in a line you are at.

In the future we may also allow a breakpoint at a COP address.

See also L<C<show display
op>|Devel::Trepan::CmdProcessor::Command::Show::Display::OP>, C<show
line>, L<C<show
program>|Devel::Trepan::CmdProcessor::Command::Show::Program> and
C<disassemble> (via plugin L<Devel::Trepan::Disassemble>).
=cut
HELP

our $MIN_ABBREV   = length('co');
use constant MAX_ARGS => 1;
our $SHORT_HELP   = "Set to show OP address in locations";

sub run($$)
{
    my ($self, $args) = @_;
    if ($DB::HAVE_MODULE{'Devel::Callsite'}) {
        $self->SUPER::run($args);
    } else {
        $self->{proc}->errmsg("You need Devel::Callsite installed to run this");
    }
}

unless (caller) {
    # Demo it.
    # DRY this.
    require Devel::Trepan::CmdProcessor;
    my $cmdproc = Devel::Trepan::CmdProcessor->new();
    my $subcmd  =  Devel::Trepan::CmdProcessor::Command::Set->new($cmdproc, 'set');
    my $dispcmd =  Devel::Trepan::CmdProcessor::Command::Set::Display->new($subcmd, 'display');
    my $opcmd   =  Devel::Trepan::CmdProcessor::Command::Set::Display::OP->new($dispcmd, 'op');
    # Add common routine
    foreach my $field (qw(min_abbrev name)) {
	printf "Field %s is: %s\n", $field, $opcmd->{$field};
    }
    my @args = qw(set display op on);
    $opcmd->run(\@args);
    @args = qw(set display op off);
    $opcmd->run(\@args);
}

1;
