# -*- coding: utf-8 -*-
# Copyright (C) 2012 Rocky Bernstein <rocky@cpan.org>
use warnings; no warnings 'redefine'; no warnings 'once';
use rlib '../../../../..';

package Devel::Trepan::CmdProcessor::Command::Load::Command;
use Cwd 'abs_path';

use Devel::Trepan::CmdProcessor::Command::Subcmd::Core;
use Devel::Trepan::DB::LineCache;

use strict;
our (@ISA, @SUBCMD_VARS);
# Values inherited from parent
use vars @Devel::Trepan::CmdProcessor::Command::Subcmd::SUBCMD_VARS;

## FIXME: do automatically.
our $CMD = "load command";

unless (@ISA) {
    eval <<"EOE";
    use constant MAX_ARGS => undef;  # unlimited.
EOE
}

@ISA = qw(Devel::Trepan::CmdProcessor::Command::Subcmd);

our $HELP = <<'HELP';
=pod

B<load commmand> {I<file-or-directory-name-1> [I<file-or-directory-name-2>...]}

Load debugger commands or directories containing debugger
commands. This is also useful if you want to change or fix a debugger
command while inside the debugger.

=cut
HELP

our $SHORT_HELP = 'Load debugger command(s)';
our $MIN_ABBREV = length('co');

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
    foreach my $file_or_dir (@args) {
        $proc->load_debugger_commands($file_or_dir);
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
