# -*- coding: utf-8 -*-
# Copyright (C) 2011-2013 Rocky Bernstein <rocky@cpan.org>

use warnings; no warnings 'redefine'; no warnings 'once';
use rlib '../../../../..';

# For highight_string
use Devel::Trepan::DB::LineCache;

package Devel::Trepan::CmdProcessor::Command::Info::Macros;
use Devel::Trepan::CmdProcessor::Command::Subcmd::Core;

@ISA = qw(Devel::Trepan::CmdProcessor::Command::Subcmd);
# Values inherited from parent
use vars @Devel::Trepan::CmdProcessor::Command::Subcmd::SUBCMD_VARS;

use constant MAX_ARGS => undef;  # Need at most this many - undef -> unlimited.
our $CMD  = "info macros";
our $HELP = <<'HELP';
=pod

info macros

info macros *

info macros I<macro1> [I<macro2> ..]

In the first form a list of the existing macro names are shown
in column format.

In the second form, all macro names and their definitions are shown.

In the last form the only definitions of the given macro names is shown.
show macro [I<name1> I<name2> ...]

If macros names are given, show their definition. If left blank, show
all macro names.
=cut
HELP

our $MIN_ABBREV = length('ma');
our $SHORT_HELP = "Show defined macros";

# sub complete($$) {
# {
#     my ($self, $prefix) = @_;
#     my @cmds = sort keys %{$proc->{macros}};
#     Trepan::Complete.complete_token(@cmds, $prefix);
# }

sub run($$) {
    my ($self, $args) = @_;
    my $proc = $self->{proc};
    my @args = @$args;
    if (scalar(@args) > 2) {
	my @macro_names;
	if ((scalar(@args)) == 3 && '*' eq $args[2]) {
	    @macro_names = sort keys %{$proc->{macros}};
	    if (scalar @macro_names == 0) {
		$proc->msg("No macros defined.");
		return;
	    }
	} else {
	    @macro_names = @args[2..$#args];
	}
	for my $macro_name (@macro_names) {
            if (exists $proc->{macros}{$macro_name}) {
		my $line = $proc->{macros}{$macro_name}->[1];
		if ($proc->{settings}{highlight} eq 'term') {
		    $line = Devel::Trepan::DB::LineCache::highlight_string($line);
		}
                my $msg = sprintf("%s: %s", $macro_name, $line);
                $proc->msg($msg);
            } else {
                $proc->errmsg("$macro_name is not a defined macro");
            }
        }
    } else {
        my @macros = sort keys %{$proc->{macros}};
        if (scalar @macros == 0) {
            $proc->msg("No macros defined.");
        } else {
            $proc->section("List of macro names currently defined:");
            my @cmds = sort @macros;
            $proc->msg($self->{cmd}->columnize_commands(\@cmds));
        }
   }
}

unless(caller) {
    # Demo it.
    # require_relative '../../mock';
    # my $cmd = MockDebugger::sub_setup(__PACKAGE__);
    # my $cmd->run($cmd->{prefix} + %w(u foo));
}

1;
