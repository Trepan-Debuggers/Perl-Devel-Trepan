# -*- coding: utf-8 -*-
# Copyright (C) 2011 Rocky Bernstein <rockb@cpan.org>
use warnings; no warnings 'redefine'; no warnings 'once';
use lib '../../../../..';

package Devel::Trepan::CmdProcessor::Command::Info::Files;

use Devel::Trepan::CmdProcessor::Command::Subcmd::Core;
use Devel::Trepan::DB::LineCache;

use strict;
use vars qw(@ISA @SUBCMD_VARS);
@ISA = qw(Devel::Trepan::CmdProcessor::Command::Subcmd);
# Values inherited from parent
use vars @Devel::Trepan::CmdProcessor::Command::Subcmd::SUBCMD_VARS;

our @DEFAULT_FILE_ARGS = qw(size mtime sha1);
our $DEFAULT_FILE_ARGS = join(' ', @DEFAULT_FILE_ARGS);

## FIXME: do automatically.
our $CMD = "show files";

our $HELP = <<"HELP";
${CMD} [{FILENAME|.|*} [all|ctime|brkpts|mtime|sha1|size|stat]]

Show information about the current file. If no filename is given and
the program is running, then the current file associated with the
current stack entry is used. Giving . has the same effect. 

Given * gives a list of all files we know about.

Sub options which can be shown about a file are:

brkpts -- Line numbers where there are statement boundaries. 
          These lines can be used in breakpoint commands.
ctime  -- File creation time
iseq   -- Instruction sequences from this file.
mtime  -- File modification time
sha1   -- A SHA1 hash of the source text. This may be useful in comparing
          source code.
size   -- The number of lines in the file.
stat   -- File.stat information

all    -- All of the above information.

If no sub-options are given, \"$DEFAULT_FILE_ARGS\" are assumed.

Examples:

${CMD}    # Show ${DEFAULT_FILE_ARGS} information about current file
${CMD} .  # same as above
${CMD} brkpts      # show the number of lines in the current file
${CMD} brkpts size # same as above but also list breakpoint line numbers
${CMD} *  # Give a list of files we know about
HELP

our $SHORT_HELP = 'Show information about the current loaded file(s)';
our $MIN_ABBREV = length('fi');

sub file_list($) 
{
    my $self = shift;
    sort((DB::LineCache::cached_files(),
	  keys(%DB::LineCache::file2file_remap)));
}

sub complete($$)
{
    my ($self, $prefix) = @_;
    my @completions = ('.', $self->file_list());
    Devel::Trepan::Complete::complete_token(\@completions, $prefix);
}

sub run($$) 
{
    my ($self, $args) = @_;
    my $proc = $self->{proc};
    $proc->msg("Not finished yet...");
}

unless (caller) {
    require Devel::Trepan;
    require Devel::Trepan::DB::LineCache;
    DB::LineCache::cache_file(__FILE__);
    print join(', ', file_list('bogus')), "\n";
    # Demo it.
    # require_relative '../../mock'
    # my($dbgr, $parent_cmd) = MockDebugger::setup('show');
    # $cmd = __PACKAGE__->new(parent_cmd);
    # $cmd->run(@$cmd->prefix);
}

# Suppress a "used-once" warning;
$HELP || scalar @SUBCMD_VARS;
