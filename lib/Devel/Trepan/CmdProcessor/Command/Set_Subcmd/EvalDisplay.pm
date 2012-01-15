# -*- coding: utf-8 -*-
# Copyright (C) 2011, 2012 Rocky Bernstein <rocky@cpan.org>
use warnings; no warnings 'redefine'; no warnings 'once';
use strict;
use rlib '../../../../..';

package Devel::Trepan::CmdProcessor::Command::Set::EvalDisplay;

use Devel::Trepan::CmdProcessor::Default;
use Devel::Trepan::CmdProcessor::Command::Subcmd::Core;

our @ISA = qw(Devel::Trepan::CmdProcessor::Command::Subcmd);
# Values inherited from parent
use vars @Devel::Trepan::CmdProcessor::Command::Subcmd::SUBCMD_VARS;
our $CMD = 'set evaldisplay';
my @DISPLAY_TYPES = @Devel::Trepan::CmdProcessor::DISPLAY_TYPES;
my $param = join('|', @DISPLAY_TYPES);
our $HELP   = <<"HELP";
${CMD} \{$param\}

Set how you want the evaluation results shown.

The 'tidy' option sets to use Data::Dumper::Perltidy. 'dumper' uses 
Data::Dumper. When the Data::Printer module is installed, 
'dprint' specifies using that.

See also 'show evaldisplay', 'eval', and 'set autoeval'.
HELP

our $SHORT_HELP = 'Set how you want the evaluation results shown';
our $MIN_ABBREV = length('evaldi');
use constant MIN_ARGS => 1;

sub complete($$) 
{
    my ($self, $prefix) = @_;
    Devel::Trepan::Complete::complete_token(\@DISPLAY_TYPES, $prefix);
}

sub run($$)
{ 
    my ($self, $args) = @_;
    my $proc = $self->{proc};
    my $evaltype = $args->[2];
    my @result = grep($_ eq $evaltype, @DISPLAY_TYPES);
    if (1 == scalar @result) {
	$proc->{settings}{evaldisplay} = $evaltype;
    } else {
	my $or_list = join(', or ', map{"'$_'"} @DISPLAY_TYPES); 
	$proc->errmsg("Expecting either $or_list; got ${evaltype}");
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
