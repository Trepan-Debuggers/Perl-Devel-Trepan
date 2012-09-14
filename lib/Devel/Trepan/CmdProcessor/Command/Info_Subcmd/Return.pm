# -*- coding: utf-8 -*-
# Copyright (C) 2011-2012 Rocky Bernstein <rockb@cpan.org>
use warnings; no warnings 'redefine'; no warnings 'once';
use rlib '../../../../..';

package Devel::Trepan::CmdProcessor::Command::Info::Return;

use Devel::Trepan::CmdProcessor::Command::Subcmd::Core;

use strict;
use vars qw(@ISA @SUBCMD_VARS);
@ISA = qw(Devel::Trepan::CmdProcessor::Command::Subcmd);
# Values inherited from parent
use vars @Devel::Trepan::CmdProcessor::Command::Subcmd::SUBCMD_VARS;

our $SHORT_HELP = "Show the value about to be returned";
our $HELP = <<'HELP';
=pod

Show the value about to be returned.
=cut
HELP

our $MIN_ABBREV = length('ret');
use constant NEED_STACK => 1;

use Data::Dumper;

sub run($$) 
{
    my ($self, $args) = @_;
    my $proc = $self->{proc};

    unless ($DB::event eq 'return') {
        $proc->errmsg("We are not stopped at a return");
        return;
    }
    my $ret_type = $proc->{dbgr}->return_type();
    if ('undef' eq $ret_type) {
        $proc->msg("Return value for $DB::_[0] is <undef>");
    } elsif ('array' eq $ret_type) {
        $proc->msg("Return array value for $DB::_[0] is:");
        my @ret = $proc->{dbgr}->return_value();
        $proc->msg(Dumper(@ret));
    } elsif ('scalar' eq $ret_type) {
        my $ret = $proc->{dbgr}->return_value() || 'undef';
        $proc->msg("Return value for $DB::_[0] is: $ret");
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
