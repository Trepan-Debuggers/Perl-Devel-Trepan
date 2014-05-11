# -*- coding: utf-8 -*-
# Copyright (C) 2013-2014 Rocky Bernstein <rocky@cpan.org>
use warnings; no warnings 'redefine'; no warnings 'once';
use rlib '../../../../../..';

package Devel::Trepan::CmdProcessor::Command::Set::Substitute::Path;
use Devel::Trepan::DB::LineCache;

use Devel::Trepan::CmdProcessor::Command::Subcmd::Subsubcmd;
use strict;
use vars qw(@ISA @SUBCMD_VARS);
@ISA = qw(Devel::Trepan::CmdProcessor::Command::Subsubcmd);

# Values inherited from parent

use vars @Devel::Trepan::CmdProcessor::Command::Subsubcmd::SUBCMD_VARS;
our $CMD = 'set display eval';
my @DISPLAY_TYPES = @Devel::Trepan::CmdProcessor::DISPLAY_TYPES;
my $param = join('|', @DISPLAY_TYPES);
=pod

=head2 Synopsis:

=cut
our $HELP   = <<"HELP";
=pod

B<set substitute path> [I<from-path>] I<to-path>

Add a substitution rule replacing I<from-path> into I<to-path> in
source file names.  If a substitution rule was previously set for
I<from-path>, the old rule is replaced by the new one. If I<from_path>
is not given use the current filename.

=cut
HELP

our $MIN_ABBREV = length('pa');
use constant MIN_ARGS => 1;
use constant MAX_ARGS => 2;
our $SHORT_HELP = 'Use PATH in place of a filename';

sub run($$)
{
    my ($self, $args) = @_;
    my ($from_path, $to_path);
    my $proc = $self->{proc};
    if (scalar(@$args) == 5) {
	$from_path = $args->[3];
	$to_path   = $args->[4];
    } else {
	$from_path = $proc->{frame}{file};
	$to_path   = $args->[3];
    }
    # FIXME: Check from_path name to see if it is loaded
    if (-f $to_path) {
	remap_file($from_path, $to_path);
    } else {
	$proc->errmsg("File ${to_path} doesn't exist");
    }
}

unless(caller) {
    # requre File::Basename;
    # Demo it.
    # my $name = basename(__FILE__, '.pm')
}

1;
