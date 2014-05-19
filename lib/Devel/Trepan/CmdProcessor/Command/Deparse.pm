# -*- coding: utf-8 -*-
# Copyright (C) 2014 Rocky Bernstein <rocky@cpan.org>
use warnings; no warnings 'redefine';
use English qw( -no_match_vars );
use rlib '../../../..';
use B::Deparse;

# require_relative '../../app/condition'

package Devel::Trepan::CmdProcessor::Command::Deparse;
use English qw( -no_match_vars );
use Devel::Trepan::DB::LineCache;
use Devel::Trepan::CmdProcessor::Validate;
use if !@ISA, Devel::Trepan::CmdProcessor::Command;
unless (@ISA) {
    eval <<'EOE';
    use constant CATEGORY   => 'files';
    use constant SHORT_HELP => 'Deparse source code';
    use constant MIN_ARGS   => 0; # Need at least this many
    use constant MAX_ARGS   => undef;
    use constant NEED_STACK => 0;
EOE
}

use strict; use vars qw(@ISA); @ISA = @CMD_ISA;
use vars @CMD_VARS;  # Value inherited from parent

our $NAME = set_name();
=head2 Synopsis:

=cut
our $HELP = <<'HELP';
=pod

B<deparse> [I<filename> | I<subroutine>]

Deparse Perl source code.

Without arguments, prints lines centered around the current
subroutine.

=head2 Examples:

 deparse            # deparse current subroutine
 deparse file.pm

=head2 See also:

L<C<list>|Devel::Trepan::CmdProcessor::Command::List>

=cut
HELP

# FIXME: Should we include all files?
# Combine with BREAK completion.
sub complete($$)
{
    my ($self, $prefix) = @_;
    my $filename = $self->{proc}->filename;
    # For line numbers we'll use stoppable line number even though one
    # can enter line numbers that don't have breakpoints associated with them
    my @completions = sort(file_list, DB::subs());
    Devel::Trepan::Complete::complete_token(\@completions, $prefix);
}

## FIXME: add options parsing

# This method runs the command
sub run($$)
{
    my ($self, $args) = @_;

    my @args     = @$args;
    my $proc     = $self->{proc};
    my $filename = $proc->{list_filename};
    my $frame    = $proc->{frame};
    my $funcname = $proc->{frame}{fn};
    my $have_func;
    if (scalar @args == 1) {
	$have_func = 1;
    } elsif (scalar @args == 2) {
	print "2\n";
	$filename = $args[1];
	my @matches = $self->{dbgr}->subs($filename);
	if (scalar(@matches) >= 1) {
	    $funcname = $matches[0][0];
	} else {
	    my $canonic_name = map_file($filename);
	    if (is_cached($canonic_name)) {
		$filename = $canonic_name;
	    }
	}
    }

    # FIXME: we assume func below, add parse options like filename, and
    if ($have_func) {
	print "5\n";
	# if ($self->{terminated}) {
	#     $self->errmsg("Command '$name' requires a running program.");
	#     return;
	# }
	my $deparse = B::Deparse->new('-p', '-sC');
	my @package_parts = split(/::/, $funcname);
	my $prefix = '';
	$prefix = join('::', @package_parts[0..length(@package_parts) - 1])
	    if @package_parts;
	my $short_func = $package_parts[-1];

	my $body = "package $prefix;\nsub $short_func" . $deparse->coderef2text(\&$funcname);
	$body = Devel::Trepan::DB::LineCache::highlight_string($body) if
	    $proc->{settings}{highlight};
	$proc->msg($body);
    } else  {
	my $cmd="$EXECUTABLE_NAME  -MO=Deparse,-sC $filename";
	print $cmd, "\n";
	my $text = `$cmd 2>&1`;
	if ($? >> 8 == 0) {
	    $text = Devel::Trepan::DB::LineCache::highlight_string($text) if
		$proc->{settings}{highlight};
	    $proc->msg($text);
	}
    }
}

unless (caller) {
    require Devel::Trepan::CmdProcessor::Mock;
    my $proc = Devel::Trepan::CmdProcessor->new(undef, 'bogus');
    my $cmd = __PACKAGE__->new($proc);
    require Devel::Trepan::DB::Sub;
    require Devel::Trepan::DB::LineCache;
    cache_file(__FILE__);
    my $frame_ary = Devel::Trepan::CmdProcessor::Mock::create_frame();
    $proc->frame_setup($frame_ary);
    $proc->{settings}{highlight} = 0;
    $cmd->run([$NAME]);
    $proc->{frame}{fn} = 'run';
    $proc->{settings}{highlight} = 1;
    $cmd->run([$NAME]);
}

1;
