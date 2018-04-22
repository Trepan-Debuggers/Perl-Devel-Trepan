# -*- coding: utf-8 -*-
# Copyright (C) 2011-2014, 2018 Rocky Bernstein <rocky@cpan.org>

use warnings; use utf8;

package Devel::Trepan::CmdProcessor::Command::Info::Macros;

use rlib '../../../../..';
# For highight_string
use if !@ISA, Devel::Trepan::DB::LineCache;
use if !@ISA, Devel::Trepan::CmdProcessor::Command::Subcmd::Core;

use strict; use types;

our @ISA = qw(Devel::Trepan::CmdProcessor::Command::Subcmd);
# Values inherited from parent
use vars @Devel::Trepan::CmdProcessor::Command::Subcmd::SUBCMD_VARS;

unless (@ISA) {
    eval <<"EOE";
    use constant MAX_ARGS => undef;  # unlimited.
EOE
}

our $CMD  = "info macros";
=pod

=head2 Synopsis:

=cut
our $HELP = <<'HELP';
=pod

info macros

B<info macros *>
B<info macros> I<macro1> [I<macro2> ..]

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

no warnings 'redefine';
sub run($self, $args) {
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
		if ($proc->{settings}{highlight}) {
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
    require Devel::Trepan::CmdProcessor;
    my $proc = Devel::Trepan::CmdProcessor->new;
    my $parent = Devel::Trepan::CmdProcessor::Command::Info->new($proc, 'info');
    my $cmd = __PACKAGE__->new($parent, 'macros');
    print $cmd->{help}, "\n";
    print "min args: ", $cmd->MIN_ARGS, "\n";
}

1;
