# -*- coding: utf-8 -*-
# Copyright (C) 2015 Rocky Bernstein <rocky@cpan.org>
use warnings; no warnings 'redefine'; no warnings 'once';
use rlib '../../../../../..';

package Devel::Trepan::CmdProcessor::Command::Set::Max::Lines;
use Devel::Trepan::CmdProcessor::Command::Subcmd::Subsubcmd;

use strict;
use vars qw(@ISA @SUBCMD_VARS);
@ISA = qw(Devel::Trepan::CmdProcessor::Command::Subsubcmd);
# Values inherited from parent

use vars @Devel::Trepan::CmdProcessor::Command::Subsubcmd::SUBCMD_VARS;

=pod

=head2 Synopsis:

=cut


our $HELP = <<"HELP";
=pod

B<set max lines> I<count>

Set maximum number of lines of trailing context around the source line.

=head2 See also:

L<C<show max lines>|Devel::Trepan::CmdProcessor::Show::Max::Lines>

=cut
HELP

our $IN_LIST      = 1;
our $MIN_ABBREV   = length('lin');
our $SHORT_HELP   = 'Set maximum trailing context lines';

sub run($$)
{
    my ($self, $args) = @_;
    my @args = @$args;
    shift @args; shift @args; shift @args;
    my $num_str = join(' ', @args);
    $self->run_set_int($num_str,
                       "The '$self->{cmd_str}' command requires a line count",
                       1, undef);
}

unless (caller) {
    # Demo it.
    require Devel::Trepan::CmdProcessor;
    my $cmdproc = Devel::Trepan::CmdProcessor->new();
    my $subcmd  =  Devel::Trepan::CmdProcessor::Command::Set->new($cmdproc, 'set');
    my $parent_cmd =  Devel::Trepan::CmdProcessor::Command::Set::Max->new($subcmd, 'lines');
    my $cmd   =  __PACKAGE__->new($parent_cmd, 'lines');
    # Add common routine
    foreach my $field (qw(min_abbrev name)) {
	printf "Field %s is: %s\n", $field, $cmd->{$field};
    }
    my @args = qw(set max lines 10);
    $cmd->run(\@args);
}

1;
