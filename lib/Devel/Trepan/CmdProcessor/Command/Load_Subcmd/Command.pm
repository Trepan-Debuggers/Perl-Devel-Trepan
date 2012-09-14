# -*- coding: utf-8 -*-
# Copyright (C) 2011-2012 Rocky Bernstein <rocky@cpan.org>
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

our @DEFAULT_FILE_ARGS = qw(size mtime sha1);
our $DEFAULT_FILE_ARGS = join(' ', @DEFAULT_FILE_ARGS);

## FIXME: do automatically.
our $CMD = "info files";

unless (@ISA) {
    eval <<"EOE";
    use constant MAX_ARGS => 8;  # Need at most this many - undef -> unlimited.
EOE
}

@ISA = qw(Devel::Trepan::CmdProcessor::Command::Subcmd);

our $HELP = <<'HELP';
=pod

load commmand {I<filename>|directory-name}

Load a debugger command or directory of debugger commands.
=cut
HELP

our $SHORT_HELP = 'Load debugger command(s)';
our $MIN_ABBREV = length('fi');

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
