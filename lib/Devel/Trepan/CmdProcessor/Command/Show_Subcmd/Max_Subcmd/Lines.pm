# -*- coding: utf-8 -*-
# Copyright (C) 2011, 2014-2015 Rocky Bernstein <rocky@cpan.org>
use warnings; no warnings 'redefine'; no warnings 'once';
use rlib '../../../../../..';

package Devel::Trepan::CmdProcessor::Command::Show::Max::Lines;

use Devel::Trepan::CmdProcessor::Command::Subcmd::Subsubcmd;

use strict;
use vars qw(@ISA @SUBCMD_VARS);
@ISA = qw(Devel::Trepan::CmdProcessor::Command::ShowIntSubsubcmd);
# Values inherited from parent

use vars @Devel::Trepan::CmdProcessor::Command::Subsubcmd::SUBCMD_VARS;

our $IN_LIST      = 1;
our $MIN_ABBREV   = length('lines');
=pod

=head2 Synopsis:

=cut

our $HELP   = <<"HELP";
=pod

B<show max lines>

Set maximum number of lines of trailing context around the source line.


=head2 See also:

L<C<set max lines>|Devel::Trepan::CmdProcessor::Set::Max::Lines>

=cut
HELP

our $SHORT_HELP   = 'Show the number of characters the debugger thinks are in a line';

unless (caller) {
    require Devel::Trepan::CmdProcessor;
    my $cmdproc = Devel::Trepan::CmdProcessor->new();
    my $subcmd  =  Devel::Trepan::CmdProcessor::Command::Show->new($cmdproc, 'set');
    my $parent_cmd =  Devel::Trepan::CmdProcessor::Command::Show::Max->new($subcmd, 'lines');
    my $cmd   =  __PACKAGE__->new($parent_cmd, 'lines');
    # Add common routine
    foreach my $field (qw(min_abbrev name)) {
	printf "Field %s is: %s\n", $field, $cmd->{$field};
    }
    my @args = qw(show max lines);
    $cmd->run(\@args);
}

1;
