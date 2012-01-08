# -*- coding: utf-8 -*-
# Copyright (C) 2011, 2012 Rocky Bernstein <rocky@cpan.org>
use warnings; no warnings 'redefine'; no warnings 'once';
use rlib '../../../../..';

package Devel::Trepan::CmdProcessor::Command::Show::EvalDisplay;

use Devel::Trepan::CmdProcessor::Command::Subcmd::Core;

@ISA = qw(Devel::Trepan::CmdProcessor::Command::Subcmd);
# Values inherited from parent
use vars @Devel::Trepan::CmdProcessor::Command::Subcmd::SUBCMD_VARS;

## FIXME: do automatically.
our $CMD  = 'show evaldisplay';
our $HELP = <<"EOH";
$CMD

Shows whether Data::Dumper ('dumper') or Data::Dumper::Perltidy ('tidy') 
is used to format evaluation results.

See also 'set evaldisplay', 'eval', and 'set autoeval'.
EOH

our $SHORT_HELP = 'Show how the evaluation results shown';
our $MIN_ABBREV = length('evaldi');

sub run($$)
{
    my ($self, $args) = @_;
    my $proc = $self->{proc};
    my $val = $proc->{settings}->{evaldisplay};
    my $msg = sprintf "Eval result display style is %s.", $val;
    $proc->msg($msg);
}

unless (caller) {
  # Demo it.
  # require_relative '../../mock'

  # # FIXME: DRY the below code
  # my ($dbgr, $cmd) = MockDebugger::setup('show');
  # $subcommand = __PACKAGE__->new(cmd);
  # $testcmdMgr = Trepan::Subcmd->new(subcommand);

  # $subcommand->run_show_bool();
  # $subcommand->summary_help($NAME);
}

1;
