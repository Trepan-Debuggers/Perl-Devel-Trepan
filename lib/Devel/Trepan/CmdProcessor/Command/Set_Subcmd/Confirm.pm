# -*- coding: utf-8 -*-
# Copyright (C) 2011, 2014-2015 Rocky Bernstein <rocky@cpan.org>
use warnings; no warnings 'redefine'; no warnings 'once';
use rlib '../../../../..';

package Devel::Trepan::CmdProcessor::Command::Set::Confirm;

use Devel::Trepan::CmdProcessor::Command::Subcmd::Core;

our @ISA = (Devel::Trepan::CmdProcessor::Command::SetBoolSubcmd);
use strict;
# Values inherited from parent
use vars @Devel::Trepan::CmdProcessor::Command::Subcmd::SUBCMD_VARS;

## FIXME: do automatically.
our $CMD = "set confirm";
=pod

=head2 Synopsis:

=cut

our $HELP   = <<"HELP";
=pod

B<set confirm> [B<on>|B<off>]

Set whether to confirm potentially dangerous operations.

Note that some commands like
L<C<quit>|Devel::Trepan::CmdProcessor::Command::Quit> and
L<C<kill>|Devel::Trepan::CmdProcessor::Command::Kill> have a C<!>
suffix which turns the confirmation off in that specific instance.

=head2 See also:

L<C<show confirm>|Devel::Trepan::CmdProcessor::Command::Show::Confirm>

=cut
HELP
our $SHORT_HELP = "Set whether to confirm potentially dangerous operations.";
our $MIN_ABBREV = length('con');

unless (caller) {
    # Demo it.
    require Devel::Trepan::CmdProcessor::Mock;
    my ($proc, $cmd) =
	Devel::Trepan::CmdProcessor::Mock::subcmd_setup();
    Devel::Trepan::CmdProcessor::Mock::subcmd_demo_bool($proc, $cmd);
}

1;
