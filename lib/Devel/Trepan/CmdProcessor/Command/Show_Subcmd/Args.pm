# -*- coding: utf-8 -*-
# Copyright (C) 2012 Rocky Bernstein <rocky@cpan.org>
use warnings; no warnings 'redefine'; no warnings 'once';
use rlib '../../../../..';
use Devel::Trepan::CmdProcessor::Command::Subcmd::Core;

package Devel::Trepan::CmdProcessor::Command::Show::Args;


@ISA = qw(Devel::Trepan::CmdProcessor::Command::Subcmd);
# Values inherited from parent
use vars @Devel::Trepan::CmdProcessor::Command::Subcmd::SUBCMD_VARS;

our $HELP = "Arguments to restart program";
our $MIN_ABBREV = length('ar');

sub run($$)
{
    my ($self, $args) = @_;
    my $proc = $self->{proc};
    my @script = $proc->restart_args();
    $proc->msg("Argument list to give program being debugged when it is started is:");
    $proc->msg(join(' ', @script));
}

unless (caller) {
  # Demo it.
  # require_relative '../../mock'

  # # FIXME: DRY the below code
  # my ($dbgr, $cmd) = MockDebugger::setup('show');
  # $subcommand = __PACKAGE__->new($cmd);
  # $testcmdMgr = Trepan::Subcmd->new($subcommand);

  # $subcommand->run_show_bool();
  # $subcommand->summary_help($NAME);
}

1;
