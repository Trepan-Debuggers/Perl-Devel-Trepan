# -*- coding: utf-8 -*-
# Copyright (C) 2011-2012, 2014-2015 Rocky Bernstein <rocky@cpan.org>
use warnings; no warnings 'redefine'; no warnings 'once';
use rlib '../../../../..';

package Devel::Trepan::CmdProcessor::Command::Set::Basename;

use Devel::Trepan::CmdProcessor::Command::Subcmd::Core;

@ISA = qw(Devel::Trepan::CmdProcessor::Command::SetBoolSubcmd);
# Values inherited from parent
use vars @Devel::Trepan::CmdProcessor::Command::Subcmd::SUBCMD_VARS;

our $SHORT_HELP = 'Set to show only file basename in showing file names';
=pod

=head2 Synopsis:

=cut

our $HELP   = <<'HELP';
=pod

B<set basename> [B<on>|B<off>]

Set to show only file basename in showing file names. If "on"
or "off" is not given, "on" is assumed.

=head2 See also:

L<C<show basename>|Devel::Trepan::CmdProcessor::Command::Show::Basename>

=cut
HELP

our $MIN_ABBREV = length('ba');

unless (caller) {
    # Demo it.
    require Devel::Trepan::CmdProcessor::Mock;
    my ($proc, $cmd) =
	Devel::Trepan::CmdProcessor::Mock::subcmd_setup();
    Devel::Trepan::CmdProcessor::Mock::subcmd_demo_bool($proc, $cmd);
}

1;
