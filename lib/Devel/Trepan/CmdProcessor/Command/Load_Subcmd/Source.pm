# -*- coding: utf-8 -*-
# Copyright (C) 2012, 2014 Rocky Bernstein <rocky@cpan.org>
use warnings; no warnings 'redefine'; no warnings 'once';
use rlib '../../../../..';

package Devel::Trepan::CmdProcessor::Command::Load::Source;
use English qw( -no_match_vars );
use Cwd 'abs_path';

use Devel::Trepan::CmdProcessor::Command::Subcmd::Core;
# use Devel::Trepan::DB::LineCache qw(file_list);

use strict;
our (@ISA, @SUBCMD_VARS);
# Values inherited from parent
use vars @Devel::Trepan::CmdProcessor::Command::Subcmd::SUBCMD_VARS;

## FIXME: do automatically.
our $CMD = "load source";

unless (@ISA) {
    eval <<"EOE";
    use constant MAX_ARGS => 0;  # Need at most this many - undef -> unlimited.
    use constant NEED_STACK => 0;
EOE
}

@ISA = qw(Devel::Trepan::CmdProcessor::Command::Subcmd);

=pod

=head2 Synopsis:

=cut

our $HELP = <<'HELP';
=pod

B<load source> {I<Perl-source-file>}

Read source lines of {I<Perl-source-file>}.

This simulates what Perl does in reading a file when debugging is
turned on, somewhat. A description of what this means is below.

The file contents are read in as a list of strings in
I<_E<lt>$filename> for the debugger to refer to; I<$filename> contains
the name I<Perl-source-file>. In addition, each entry of this list is
a dual variable. In a non-numeric context, an entry is a string of the
line contents including the trailing C<\n>.

But in numeric context, an entry of the list is I<true> if that line
is traceable or has a COP instruction in it which allows the debugger
to take control.
=cut
HELP

our $SHORT_HELP = 'Read Perl source file(s)';
our $MIN_ABBREV = length('so');

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
                Devel::Trepan::DB::LineCache::load_file($source);
                Devel::Trepan::DB::LineCache::update_cache($source,
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
