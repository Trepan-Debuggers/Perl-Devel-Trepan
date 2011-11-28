# -*- coding: utf-8 -*-
# Copyright (C) 2011 Rocky Bernstein <rocky@cpan.org>
use warnings; no warnings 'redefine'; no warnings 'once';
use rlib '../../../../..';

package Devel::Trepan::CmdProcessor::Command::Set::EvalDisplay;

use Devel::Trepan::CmdProcessor::Command::Subcmd::Core;

@ISA = qw(Devel::Trepan::CmdProcessor::Command::Subcmd);
# Values inherited from parent
use vars @Devel::Trepan::CmdProcessor::Command::Subcmd::SUBCMD_VARS;

our $HELP = 'Set how you want the evaluation results shown';
our $MIN_ABBREV = length('evaldi');
use constant MIN_ARGS => 1;

# sub complete($$) 
# {
#     my ($self, $prefix) = @_;
#     Devel::Trepan::Complete::complete_token(qw(on off reset), $prefix);
# }

sub run($$)
{ 
    my ($self, $args) = @_;
    my $proc = $self->{proc};
    my $evaltype = $args->[2];
    if ('tidy' eq $evaltype || $evaltype eq 'dumper') {
	$proc->{settings}{evaldisplay} = $evaltype;
    } else {
	$proc->errmsg("Expecting either 'tidy' or 'dumper', got ${evaltype}");
	return;
    }
    $proc->{commands}{show}->run(['show', 'evaldisplay']);
}

unless (caller) {
  # Demo it.
  # require_relative '../../mock'

  # # FIXME: DRY the below code
  # my $cmd = 
  #   Devel::Trepan::MockDebugger::sub_setup(__PACKAGE__, 0);
  # $cmd->run(@$cmd->prefix + ('off'));
  # $cmd->run(@$cmd->prefix + ('ofn'));
  # $cmd->run(@$cmd->prefix);
  # print $cmd->save_command(), "\n";

}

1;
