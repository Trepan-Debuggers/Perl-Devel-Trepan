# -*- coding: utf-8 -*-
# Copyright (C) 2011-2012, 2014 Rocky Bernstein <rocky@cpan.org>
use warnings; no warnings 'redefine'; no warnings 'once';
use rlib '../../../../../..';

package Devel::Trepan::CmdProcessor::Command::Show::Display::Eval;

use Devel::Trepan::CmdProcessor::Command::Subcmd::Subsubcmd;

use strict;
use vars qw(@ISA @SUBCMD_VARS);
@ISA = qw(Devel::Trepan::CmdProcessor::Command::ShowBoolSubsubcmd);
# Values inherited from parent
use vars @Devel::Trepan::CmdProcessor::Command::Subsubcmd::SUBCMD_VARS;

## FIXME: do automatically.
our $CMD  = 'show display eval';
our $HELP = <<"EOH";
$CMD

Shows whether Data::Dumper ('dumper') or Data::Dumper::Perltidy ('tidy')
is used to format evaluation results.

See also 'set display eval', 'eval', and 'set autoeval'.
EOH

our $SHORT_HELP = 'Show how the evaluation results are displayed';
our $MIN_ABBREV = length('ev');

sub run($$)
{
    my ($self, $args) = @_;
    my $proc = $self->{proc};
    my $key  = $self->{subcmd_setting_key};
    my $val  = $proc->{settings}{$key};
    my $msg = sprintf "Eval result display style is %s.", $val;
    $proc->msg($msg);
}

unless (caller) {
    # Demo it.
    require Devel::Trepan;
    # require_relative '../../mock'

    # # FIXME: DRY the below code
    # my ($dbgr, $cmd) = MockDebugger::setup('show');
    # $subcommand = __PACKAGE__->new(cmd);
    # $testcmdMgr = Trepan::Subcmd->new(subcommand);

    # $subcommand->run_show_bool();
    # $subcommand->summary_help($NAME);
}

1;
