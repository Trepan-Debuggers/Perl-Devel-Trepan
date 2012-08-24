# -*- coding: utf-8 -*-
# Copyright (C) 2012 Rocky Bernstein <rocky@cpan.org>

# Until I work out how to get Devel::Peek::Dump io redirected
return 'Skip me!';

use warnings; no warnings 'redefine';

use rlib '../../../../../..';
use Devel::Peek;

package Devel::Trepan::CmdProcessor::Command::Info::Variables::Dump;
our @ISA;

use Devel::Trepan::CmdProcessor::Command::Subcmd::Subsubcmd;

our $CMD = "info variables dump";
my  @CMD = split(/ /, $CMD);
unless (@ISA) {
    eval <<'EOE';
    use constant MIN_ARGS   => 1;
    use constant MAX_ARGS   => 1;
EOE
};
use strict;

our $MIN_ABBREV = length('dum');

our $HELP = <<"HELP";
${CMD} VAR

Use Devel::Peek::Dump to give information about VAR
HELP

our $SHORT_HELP = 'Devel::Peek::Dump variable';

@ISA = qw(Devel::Trepan::CmdProcessor::Command::Subsubcmd);

sub run($$)
{
    my ($self, $args) = @_;
    my @ARGS = splice(@{$args}, scalar(@CMD));

    # FIXME: 4 below is a magic fixup constant, also found in
    # DB::finish.  Remove it.
    my $code_to_eval = "Devel::Peek::Dump($ARGS[0])";
    # my $opts = {return_type => '2>'};
    my $opts = {return_type => '$'};
    $self->{proc}->eval($code_to_eval, $opts, 4);
}

  
# Demo it
unless (caller) {
}

1;
