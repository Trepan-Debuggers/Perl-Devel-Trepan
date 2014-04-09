# -*- coding: utf-8 -*-
# Copyright (C) 2014 Rocky Bernstein <rocky@cpan.org>
use warnings; no warnings 'redefine'; no warnings 'once';
use rlib '../../../../..';
use strict;

package Devel::Trepan::CmdProcessor::Command::Set::TTY;

use constant MIN_ARGS   => 0;
use constant MAX_ARGS   => 0;

use vars qw(@ISA @SUBCMD_VARS $slave_tty $master_tty);
our @ISA = qw(Devel::Trepan::CmdProcessor::Command::Subcmd);

use IO::Pty;

our $HELP   = <<"HELP";
Set tty

The input and output tty.
those events.
HELP
our $SHORT_HELP   = "Set tty.";

our $MIN_ABBREV = length('tt');

sub run($$)
{
    my ($self, $args) = @_;
    print @$args, "\n";
    if (scalar @$args == 2) {
	my $intf = $self->{proc}{interfaces};
	$master_tty = IO::Pty->new();
	$slave_tty  = $master_tty->slave;
	$self->{proc}->msg($slave_tty->ttyname());
	$self->{proc}->msg($master_tty->ttyname());
	$intf->[-1]{output}{output} = $slave_tty;
	$intf->[-1]{input}{input} = $slave_tty;
    } else {
        $self->{proc}->errmsg("wrong number of args - need none");
    }
}
unless (caller) {
    # Demo it.
    require Devel::Trepan;
    # require_relative '../../mock'
    # dbgr, parent_cmd = MockDebugger::setup('set', false)
    # cmd              = Trepan::SubSubcommand::SetMax.new(dbgr.core.processor,
    #                                                      parent_cmd)
    # cmd.run(cmd.prefix + ['string', '30'])

    # %w(s lis foo).each do |prefix|
    #   p [prefix, cmd.complete(prefix)]
    # end
}

1;
