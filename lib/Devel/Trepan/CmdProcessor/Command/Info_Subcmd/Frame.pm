# -*- coding: utf-8 -*-
# Copyright (C) 2011 Rocky Bernstein <rockb@cpan.org>
use warnings; no warnings 'redefine'; no warnings 'once';
use lib '../../../../..';

package Devel::Trepan::CmdProcessor::Command::Info::Frame;

use Devel::Trepan::CmdProcessor::Command::Subcmd::Core;

use strict;
use vars qw(@ISA @SUBCMD_VARS);
@ISA = qw(Devel::Trepan::CmdProcessor::Command::Subcmd);
# Values inherited from parent
use vars @Devel::Trepan::CmdProcessor::Command::Subcmd::SUBCMD_VARS;

our $HELP = 'Show information about the selected frame';
our $MIN_ABBREV = length('fr');

sub run($$) 
{
    my ($self, $args) = @_;
    my $proc = $self->{proc};

    # FIXME: Frame.pm should be used and should cache frames
    my @bt = $proc->{dbgr}->backtrace(0, 1);
    my $frame = $bt[0] || $proc->{frame};

    my $m = sprintf("Frame %2d", $proc->{frame_index});
    $proc->section($m);
    my @titles = qw(package function file line);
    my $i=-1;
    for my $field (qw(pkg fn file line)) {
	$i++;
	next unless exists $frame->{$field} && $frame->{$field};
	$m = "  ${titles[$i]}: " . $frame->{$field};
	$proc->msg($m);
    }
    for my $field (qw(wantarray is_require)) {
	next unless $frame->{$field};
	$m = "  ${field}: " . $frame->{$field};
	$proc->msg($m);
    }
    my $args_ary = $frame->{args};
    if ($args_ary) {
	$m = sprintf "  args: %s", join(', ', @$args_ary);
	$proc->msg($m);
    }
}

unless (caller) {
    require Devel::Trepan;
    # Demo it.
    # require_relative '../../mock'
    # my($dbgr, $parent_cmd) = MockDebugger::setup('show');
    # $cmd = __PACKAGE__->new(parent_cmd);
    # $cmd->run(@$cmd->prefix);
}

# Suppress a "used-once" warning;
$HELP || scalar @SUBCMD_VARS;
