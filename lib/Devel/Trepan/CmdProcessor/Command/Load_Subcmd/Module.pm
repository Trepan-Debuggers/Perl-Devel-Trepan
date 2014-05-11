# -*- coding: utf-8 -*-
# Copyright (C) 2012, 2014 Rocky Bernstein <rocky@cpan.org>
use warnings; no warnings 'redefine';
use rlib '../../../../..';

package Devel::Trepan::CmdProcessor::Command::Load::Module;
use Cwd 'abs_path';

# FIXME: allow specifiying just the Perl module name,
# e.g. File::Basename.

use Devel::Trepan::CmdProcessor::Command::Subcmd::Core;

use strict;
our (@ISA, @SUBCMD_VARS);
# Values inherited from parent
use vars @Devel::Trepan::CmdProcessor::Command::Subcmd::SUBCMD_VARS;

unless (@ISA) {
    eval <<"EOE";
    use constant MAX_ARGS => 0;  # Need at most this many - undef -> unlimited.
EOE
}

@ISA = qw(Devel::Trepan::CmdProcessor::Command::Subcmd);

=pod

=head2 Synopsis:

=cut

our $HELP = <<'HELP';
=pod

B<load module> {I<Perl-module-file>}

Load or reload a Perl module. This is like I<require> with a file
name, but we force the load or reload. Use this if you change the Perl
module while you are debugging and it want those changes to take
effect in both the debugged program and inside the debugger.

Note however that any functions along the call stack will not be
changed.
=cut
HELP

our $SHORT_HELP = '(re)load Perl module file(s)';
our $MIN_ABBREV = length('mo');

sub complete($$)
{
    my ($self, $prefix) = @_;
    $self->{proc}->filename_complete($prefix);
}

sub run($$)
{
    my ($self, $args) = @_;
    my $proc = $self->{proc};
    my @args = @$args; shift @args; shift @args;
    foreach my $module (@args) {
        $module .= '.pm' unless -r $module || substr($module,-3,3) eq '.pm';
        if (-r $module) {
            my $rc = do $module;
            if ($rc) {
		$proc->msg("Perl module file $module loaded");
	    } else {
                if ($@) {
                    $proc->errmsg("Trouble reading ${module}: $@");
                } else {
                    $proc->errmsg("Perl module ${module} gave invalid return");
                }
            }
        } else {
            $proc->errmsg("Can't find Perl module file $module");
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
