# -*- coding: utf-8 -*-
# Copyright (C) 2013 Rocky Bernstein <rocky@cpan.org>
use warnings; no warnings 'redefine'; no warnings 'once';
use rlib '../../../../../..';

package Devel::Trepan::CmdProcessor::Command::Set::Substitute::String;
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
our $HELP   = <<"HELP";
=pod

B<set substitute string> [I<from-file>] I<string>

Use the contents of string variable I<string-var> as the source text for
I<from-file>.  If a substitution rule was previously set for
I<from-file>, the old rule is replaced by the new one. If I<from_file>
is not given use the current filename.
=cut
HELP

our $MIN_ABBREV = length('st');
use constant MIN_ARGS => 1;
use constant MAX_ARGS => 2;
our $SHORT_HELP = 'Use STRING in place of a filename';

sub run($$)
{
    my ($self, $args) = @_;
    my ($from_file, $string);
    my $proc = $self->{proc};
    if (scalar(@$args) == 5) {
	$from_file = $args->[3];
	$string    = $args->[4];
    } else {
	$from_file = $proc->{frame}{file};
	$string    = $args->[3];
    }

    my $opts = {return_type       => '$',
		fix_file_and_line => 1,
    };
    my $string_value = eval($string);

    # FIXME: Check string name to see if it is loaded

    if (!$@ && defined($string_value)) {
	my $filename = remap_string_to_tempfile($string_value);
	remap_file($from_file, $filename);
	$proc->msg("Temporary file ${filename} with string contents created");
    } else {
	$proc->errmsg("Can't get string value");
    }
}

unless(caller) {
    # requre File::Basename;
    # Demo it.
    # my $name = basename(__FILE__, '.pm')
}

1;
