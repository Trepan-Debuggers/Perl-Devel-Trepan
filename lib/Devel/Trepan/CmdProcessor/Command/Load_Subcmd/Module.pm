# -*- coding: utf-8 -*-
# Copyright (C) 2012 Rocky Bernstein <rocky@cpan.org>
use warnings; no warnings 'redefine'; no warnings 'once';
use rlib '../../../../..';

package Devel::Trepan::CmdProcessor::Command::Load::Module;
use Cwd 'abs_path';

use Devel::Trepan::CmdProcessor::Command::Subcmd::Core;
use Devel::Trepan::DB::LineCache;

use strict;
our (@ISA, @SUBCMD_VARS);
# Values inherited from parent
use vars @Devel::Trepan::CmdProcessor::Command::Subcmd::SUBCMD_VARS;

## FIXME: do automatically.
our $CMD = "load module";

unless (@ISA) {
    eval <<"EOE";
    use constant MAX_ARGS => 0;  # Need at most this many - undef -> unlimited.
EOE
}

@ISA = qw(Devel::Trepan::CmdProcessor::Command::Subcmd);

our $HELP = <<'HELP';
=pod

load module {I<Perl-module-file>}

Load or reload a Perl module. This is like I<require> with a file name
but we force a load or reload. This is useful if you wanto to changes the
Perl module while you are debugging it and want to reread the module.

Note however that any functions along the call stack will not be
changed.

=cut
HELP

our $SHORT_HELP = 'Load Perl module file(s)';
our $MIN_ABBREV = length('mo');

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
    foreach my $module (@args) {
	$module .= '.pm' unless -r $module || substr($module,-3,3) eq '.pm';
	if (-r $module) {
	    my $rc = do $module;
	    unless ($rc) {
		if ($@) {
		    $self->errmsg("Trouble reading ${module}: $@");
		} else {
		    $self->errmsg("Perl module ${module} gave invalid return");
		}
	    }
	} else {
	    $self->errmsg("Can't find Perl module file $module");
	}
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
