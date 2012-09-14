# -*- coding: utf-8 -*-
# Copyright (C) 2011-2012 Rocky Bernstein <rocky@cpan.org>
use warnings; no warnings 'redefine'; no warnings 'once';
use rlib '../../../../..';

package Devel::Trepan::CmdProcessor::Command::Set::Return;

use Devel::Trepan::CmdProcessor::Command::Subcmd::Core;

use strict;
use vars qw(@ISA @SUBCMD_VARS);
@ISA = qw(Devel::Trepan::CmdProcessor::Command::Subcmd);
# Values inherited from parent
use vars @Devel::Trepan::CmdProcessor::Command::Subcmd::SUBCMD_VARS;

our $SHORT_HELP = "Set the value about to be returned";
our $HELP = <<'HELP';
=pod

Set the value about to be returned.
=cut
HELP

use constant MIN_ARGS   => 1;
use constant MAX_ARGS   => 1;
use constant NEED_STACK => 1;
our $MIN_ABBREV = length('ret');

use Data::Dumper;

sub run($$) 
{
    my ($self, $args) = @_;
    my $proc = $self->{proc};
    my @args = @$args;
    shift @args;
    unless ($DB::event eq 'return') {
        $proc->errmsg("We are not stopped at a return");
        return;
    }
    my $ret_type = $proc->{dbgr}->return_type();
    if ('undef' eq $ret_type) {
        $proc->msg("Return value is <undef>");
    } elsif ('array' eq $ret_type) {
        # Not quite right, but we'll use this for now.
        my @new_value = eval(join(' ', @args));
        @DB::return_value = @new_value;
        $proc->msg("Return array value set to:");
        $proc->msg(Dumper(@new_value));
    } elsif ('scalar' eq $ret_type) {
        my $new_value = eval(join(' ', @args));
        $DB::return_value = $new_value;
        $proc->msg("Return value set to: $new_value");
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
