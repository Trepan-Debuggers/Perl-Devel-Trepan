# -*- coding: utf-8 -*-
# Copyright (C) 2014 Rocky Bernstein <rocky@cpan.org>
use warnings; use utf8;
use rlib '../../../../..';

package Devel::Trepan::CmdProcessor::Command::Load::Subcmd;
use Cwd 'abs_path';

use Devel::Trepan::CmdProcessor::Command::Subcmd::Core;
use Devel::Trepan::DB::LineCache;

use strict;
our (@ISA, @SUBCMD_VARS);
# Values inherited from parent
use vars @Devel::Trepan::CmdProcessor::Command::Subcmd::SUBCMD_VARS;

## FIXME: do automatically.
our $CMD = "load subcmd";

unless (@ISA) {
    eval <<"EOE";
    use constant MIN_ARGS => 1;
    use constant MAX_ARGS => 2;
    use constant NEED_STACK => 0;
EOE
}

@ISA = qw(Devel::Trepan::CmdProcessor::Command::Subcmd);

our $HELP = <<'HELP';
=pod

B<load subcmd> I<command>  [I<Trepan-subcmd-module>]

Load debugger subcommands of command
I<command>. [I<Trepan-subcmd-module>] is the file name a Devel::Trepan
subcommand module. If not given, we'll reload all subcommands under
command. This may or not be in the directory you were expecting;
beware when reloading everything.

This command is useful if you want to add, change, or fix a debugger
command while inside the debugger.
=cut
HELP

our $SHORT_HELP = 'Load debugger sub-command(s)';
our $MIN_ABBREV = length('sub');

no warnings 'redefine';
# sub complete($$)
# {
#     my ($self, $prefix) = @_;
#     my @completions = ('.', DB::LineCache::file_list());
#     Devel::Trepan::Complete::complete_token(\@completions, $prefix);
# }

sub run($$)
{
    my ($self, $args) = @_;
    my $proc = $self->{proc};
    my @args = @$args; shift @args; shift @args;
    my $cmd_name = shift @args;
    my $mgr = $proc->{commands}{$cmd_name};
    if ($mgr) {
	if ($mgr->can('load_debugger_subcommand')) {
	    if (scalar @args == 0) {
		$mgr->load_debugger_subcommands();
		$proc->msg("Subcommands of command '$cmd_name' reloaded");
	    } else {
		my $trepan_subcmd_module = shift @args;
		if (-r $trepan_subcmd_module) {
		    my $cmd="";
		    if ($mgr->load_debugger_subcommand(ucfirst
						       $cmd_name,
						       $trepan_subcmd_module)) {
			my $msg = sprintf("File '%s' of command '%s' loaded",
					  $trepan_subcmd_module, $cmd_name);
			$proc->msg($msg);
		    }
		} else {
		    $proc->errmsg("File '$trepan_subcmd_module' is not readable")
		}
	    }
	} else {
	    $proc->errmsg("Command '$cmd_name' is does not have sub commands")
	}
    } else {
	$proc->errmsg("Can't find debugger command: '$cmd_name'")
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
