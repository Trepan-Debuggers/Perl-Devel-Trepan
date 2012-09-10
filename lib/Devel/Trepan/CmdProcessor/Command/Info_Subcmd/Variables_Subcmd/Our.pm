# -*- coding: utf-8 -*-
# Copyright (C) 2011-2012 Rocky Bernstein <rocky@cpan.org>
use warnings; no warnings 'redefine'; no warnings 'once';
use rlib '../../../../..';
package Devel::Trepan::CmdProcessor::Command::Info::Variables::Our;

use vars qw(@ISA @SUBCMD_VARS);
use strict;
use Devel::Trepan::CmdProcessor::Command::Info_Subcmd::Variables_Subcmd::My;
use PadWalker qw(peek_our);

our $CMD = "info variables our";
my  @CMD = split(/ /, $CMD);
use constant MAX_ARGS => undef;
use constant NEED_STACK => 1;
our $MIN_ABBREV = length('o');
our $HELP   = <<'HELP';
=pod

info variables our

List C<our> variables at the current stack level.
=cut
HELP
our $SHORT_HELP   = "Information about 'our' variables.";

@ISA = qw(Devel::Trepan::CmdProcessor::Command::Info::Variables::My);

sub run($$)
{
    my ($self, $args) = @_;
    # FIXME: combine with My.pm
    my $i = 0;

    while (my ($pkg, $file, $line, $fn) = caller($i++)) { ; };
    my $diff = $i - $DB::stack_depth;

    # FIXME: 4 is a magic fixup constant, also found in DB::finish.
    # Remove it.
    my $var_hash = peek_our($diff + $self->{proc}{frame_index} + 4);
    my @ARGS = splice(@{$args}, scalar(@CMD));
    $self->process_args(\@ARGS, $var_hash, 'our');
}

unless (caller) { 
    # Demo it.
    require Devel::Trepan;
}

1;
