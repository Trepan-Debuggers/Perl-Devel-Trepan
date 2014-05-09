# -*- coding: utf-8 -*-
# Copyright (C) 2011, 2014 Rocky Bernstein <rockb@cpan.org>
use warnings; no warnings 'redefine'; no warnings 'once';
use rlib '../../../../..';

package Devel::Trepan::CmdProcessor::Command::Show::Version;

use Devel::Trepan::CmdProcessor::Command::Subcmd::Core;

use strict;
use vars qw(@ISA @SUBCMD_VARS);
@ISA = qw(Devel::Trepan::CmdProcessor::Command::Subcmd);
# Values inherited from parent
use vars @Devel::Trepan::CmdProcessor::Command::Subcmd::SUBCMD_VARS;

# =pod
#
# =head2 Synopsis:
#
# =cut
our $HELP = <<"EOH";
=pod

B<show version>

Show debugger name and version
=cut
EOH

our $SHORT_HELP = "Show debugger name and version";

sub run($$) {
    my ($self, $args) = @_;
    $self->{proc}->msg(Devel::Trepan::show_version());
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
