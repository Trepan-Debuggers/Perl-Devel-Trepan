# -*- coding: utf-8 -*-
# Copyright (C) 2011 Rocky Bernstein <rockb@cpan.org>
use warnings; no warnings 'redefine'; no warnings 'once';
use rlib '../../../../..';

package Devel::Trepan::CmdProcessor::Command::Info::Frame;

use Devel::Trepan::CmdProcessor::Command::Subcmd::Core;

use strict;
our (@ISA, @SUBCMD_VARS);
# Values inherited from parent
use vars @Devel::Trepan::CmdProcessor::Command::Subcmd::SUBCMD_VARS;

## FIXME: do automatically.
our $CMD = "info frame";

unless (@ISA) {
    eval <<"EOE";
    use constant MAX_ARGS => 1;  # Need at most this many - undef -> unlimited.
EOE
}
@ISA = qw(Devel::Trepan::CmdProcessor::Command::Subcmd);

our $HELP = <<"HELP";
${CMD} [FRAME_NUM]

Show information about FRAME_NUM.  If no frame number is given, use
the selected frame

See also 'info variables my' and 'info variables our'.
HELP

our $SHORT_HELP = 'Show information about the selected frame';
our $MIN_ABBREV = length('fr');

sub complete($$)
{ 
    my ($self, $prefix) = @_;
    $self->{proc}->frame_complete($prefix, 1);
}

sub run($$) 
{
    my ($self, $args) = @_;
    my $proc = $self->{proc};
    my ($frame, $frame_num);

    if (@$args == 3) {
	my ($low, $high) = $proc->frame_low_high(0);
    	my $opts = {
	    min_value => $low, 
	    max_value => $high
    	};
    	$frame_num = $proc->get_an_int($args->[2], $opts);
    	return unless defined $frame_num;
	$frame_num += $proc->{stack_size} if $frame_num < 0;
	$frame     = $proc->{frames}[$frame_num];
    } else {
	$frame_num = $proc->{frame_index};
	$frame     = $proc->{frame};
    }

    my $is_last = $frame_num == $proc->{stack_size}-1;
    my $m = sprintf("Frame %2d", $frame_num);
    $proc->section($m);
    my @titles = qw(package function file line);
    my $i=-1;
    for my $field (qw(pkg fn file line)) {
	$i++;
	next unless exists $frame->{$field} && $frame->{$field};
	next if $field eq 'fn' && $is_last;
	$m = "  ${titles[$i]}: " . $frame->{$field};
	$proc->msg($m);
    }
    return if $is_last;
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
