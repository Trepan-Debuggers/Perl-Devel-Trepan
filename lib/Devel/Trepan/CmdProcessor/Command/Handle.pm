# -*- coding: utf-8 -*-
#  Copyright (C) 2011 Rocky Bernstein
#
#  This program is free software: you can redistribute it and/or modify
#  it under the terms of the GNU General Public License as published by
#  the Free Software Foundation, either version 3 of the License, or
#  (at your option) any later version.
#
#  This program is distributed in the hope that it will be useful,
#  but WITHOUT ANY WARRANTY; without even the implied warranty of
#  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#  GNU General Public License for more details.
#
#  You should have received a copy of the GNU General Public License
#  along with this program.  If not, see <http://www.gnu.org/licenses/>.

package Devel::Trepan::CmdProcessor::Command::Handle;
use English qw( -no_match_vars );
use if !@ISA, Devel::Trepan::CmdProcessor::Command ;

unless (@ISA) {
    eval <<"EOE";
use constant CATEGORY   => 'running';
use constant NEED_STACK => 0;
use constant SHORT_HELP => 
    'Specify a how to handle a signal';
use constant MIN_ARGS  => 1;   # Need at least this many
use constant MAX_ARGS  => undef;  # Need at most this many - undef -> unlimited.
EOE
}

use strict; use vars qw(@ISA); @ISA = @CMD_ISA;
use vars @CMD_VARS;  # Value inherited from parent

our $NAME = set_name();
our $HELP = <<"HELP";
${NAME} [SIG [action1 action2 ...]]

Specify how to handle a signal SIG. SIG can be a signal name like
SIGINT or a signal number like 2. The absolute value is used for
numbers so -9 is the same as 9 (SIGKILL). When signal names are used,
you can drop off the leading "SIG" if you want. Also letter case is
not important either.

Arguments are signals and actions to apply to those signals.
recognized actions include "stop", "nostop", "print", "noprint",
"pass", "nopass", "ignore", or "noignore".

- "Stop" means reenter debugger if this signal happens (implies "print" and
  "nopass").
- "Print" means print a message if this signal happens.
- "Pass" means let program see this signal; otherwise the program see it.
- "Ignore" is a synonym for "nopass"; "noignore" is a synonym for "pass".

Without any action names the current settings are shown.

Examples:
  handle INT         # Show current settings of SIGINT
  handle SIGINT      # same as above
  handle int         # same as above
  handle 2           # Probably the same as above
  handle -2          # the same as above
  handle INT nostop  # Don't stop in the debugger on SIGINT
HELP

sub run($$) {
    my ($self, $args) = @_;
    my $proc = $self->{proc};

    my $sigmgr = $self->{dbgr}{sigmgr};
    if ($sigmgr->action($proc->{cmd_argstr}) &&
	scalar(@{$args}) > 2) {
	# Show results of recent change
	$sigmgr->info_signal([$args->[1]]);
    }
}

unless(caller) {
    require Devel::Trepan::DB;
    require Devel::Trepan::Core;
    my $db = Devel::Trepan::Core->new;
    my $intf = Devel::Trepan::Interface::User->new(undef, undef, {readline => 0});
    my $proc = Devel::Trepan::CmdProcessor->new([$intf], $db);
    my $cmd = __PACKAGE__->new($proc);
    $cmd->run([$NAME]);
}
