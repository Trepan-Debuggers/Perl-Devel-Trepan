# -*- coding: utf-8 -*-
# Copyright (C) 2012 Rocky Bernstein <rocky@cpan.org>
use warnings; no warnings 'redefine'; no warnings 'once';
use rlib '../../../../..';

package Devel::Trepan::CmdProcessor::Command::Load::Source;
use English qw( -no_match_vars );
use Cwd 'abs_path';

use Devel::Trepan::CmdProcessor::Command::Subcmd::Core;
use Devel::Trepan::DB::LineCache;

use strict;
our (@ISA, @SUBCMD_VARS);
# Values inherited from parent
use vars @Devel::Trepan::CmdProcessor::Command::Subcmd::SUBCMD_VARS;

## FIXME: do automatically.
our $CMD = "load source";

unless (@ISA) {
    eval <<"EOE";
    use constant MAX_ARGS => 0;  # Need at most this many - undef -> unlimited.
EOE
}

@ISA = qw(Devel::Trepan::CmdProcessor::Command::Subcmd);

our $HELP = <<'HELP';
=pod

B<load source> {I<Perl-source-file>}

Read source lines of {I<Perl-source-file>}.

Somewhat simulates what Perl does in reading a file when debugging is
turned on. We the file contents as a list of strings in
I<_E<gt>$filename>. But also entry is a dual variable. In numeric
context, each entry of the list is I<true> if that line is traceable
or break-pointable (is the address of a COP instruction). In a
non-numeric context, each entry is a string of the line contents
including the trailing C<\n>.

=cut
HELP

our $SHORT_HELP = 'Read Perl source file(s)';
our $MIN_ABBREV = length('so');

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
    foreach my $source (@args) {
        if (-r $source) {
            ## FIXME put into a common routine and use in bin/trepan.pl as
            ## well
            # Check that the debugged Perl program is syntactically valid.
            my $cmd = "$EXECUTABLE_NAME -c $source 2>&1";
            my $output = `$cmd`;
            my $rc = $? >>8;
            if ($rc) {
                $proc->errmsg("$output");
            } else {

                # FIXME: These two things should be one routine. Also change 
                # 10test-linecache.t
                DB::LineCache::load_file($source);
                DB::LineCache::update_cache($source, 
                                            {use_perl_d_file => 1});

                $proc->msg("Read in lines of Perl source file $source");
            }
        } else {
            $proc->errmsg("Don't see ${source} for reading");
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
