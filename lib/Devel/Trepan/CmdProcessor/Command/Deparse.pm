# -*- coding: utf-8 -*-
# Copyright (C) 2014-2015 Rocky Bernstein <rocky@cpan.org>
use warnings; no warnings 'redefine';
use English qw( -no_match_vars );
use rlib '../../../..';
use B::DeparseTree;
use B::Deparse;

# require_relative '../../app/condition'

package Devel::Trepan::CmdProcessor::Command::Deparse;
use English qw( -no_match_vars );
use Devel::Trepan::DB::LineCache;
use Devel::Trepan::CmdProcessor::Validate;
use if !@ISA, Devel::Trepan::CmdProcessor::Command;
use Getopt::Long qw(GetOptionsFromArray);

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

B<deparse> [I<B::Deparse-options>] [I<filename> | I<subroutine>]

B::Deparse options:

    -d  Output data values using Data::Dumper
    -l  Add '#line' declaration
    -P  Disable prototype checking
    -q  Expand double-quoted strings

Deparse Perl source code using L<B::Deparse>.

Without arguments, deparses the current statement, if we can

=head2 Examples:

  deparse            # deparse current statement
  deparse file.pm
  deparse -l file.pm

=head2 See also:

L<C<list>|Devel::Trepan::CmdProcessor::Command::List>, and
L<B::Deparse> for more information on deparse options.

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

sub parse_options($$)
{
    my ($self, $args) = @_;
    my @opts = ();
    my $result =
	&GetOptionsFromArray($args,
			     '-d'  => sub {push(@opts, '-d') },
			     '-l'  => sub {push(@opts, '-l') },
			     '-P'  => sub {push(@opts, '-P') },
			     '-q'  => sub {push(@opts, '-q') }
        );
    @opts;
}

sub show_addr($$) {
    my ($deparse, $addr) = @_;
    return unless $addr;
    my $op_info = $deparse->{optree}{$addr};
    if ($op_info) {
	# use Data::Printer; Data::Printer::p $op_info;
	my $text = $deparse->indent_info($op_info);
	return $op_info, $text;
    }
    return (undef, undef);
}

# This method runs the command
sub run($$)
{
    my ($self, $args) = @_;
    my @args     = @$args;
    @args = splice(@args, 1, scalar(@args), -2);
    my @options = parse_options($self, \@args);
    my $proc     = $self->{proc};
    my $filename = $proc->{list_filename};
    my $frame    = $proc->{frame};
    my $funcname = $proc->{frame}{fn};
    my $want_runtime_position = 0;
    if (scalar @args == 0) {
	# Use function if there is one. Otherwise use
	# the current file.
	if ($proc->{stack_size} > 0 && $funcname) {
	    $want_runtime_position = 1;
	}
    } elsif (scalar @args == 1) {
	if ($args[0] =~ /^0x/) {
	    $want_runtime_position = 1;
	} else {
	    $filename = $args[0];
	    my $subname = $filename;
	    $subname = "main::$subname" if index($subname, '::') == -1;
	    my @matches = $self->{dbgr}->subs($subname);
	    if (scalar(@matches) >= 1) {
		$funcname = $subname;
		$want_runtime_position = 1;
	    } else {
		my $canonic_name = map_file($filename);
		if (is_cached($canonic_name)) {
		    $filename = $canonic_name;
		}
	    }
	}
    } else {
	$proc->errmsg('Expecting exactly one file or function name');
	return;
    }

    my $text;
    # FIXME: we assume func below, add parse options like filename, and
    if ($want_runtime_position) {
	my $deparse = B::DeparseTree->new("-p", "-l", "-sC");
	if (scalar @args == 0 && $proc->{op_addr}) {
	    if ($funcname eq "DB::DB") {
		$deparse->deparse_root(B::main_root);
	    } else {
		$deparse->coderef2list(\&$funcname);
	    }
	    my ($op_info, $mess) = show_addr($deparse, $proc->{op_addr});
	    if ($op_info) {
		my ($dummy, $mess2) = show_addr($deparse, $op_info->{parent});
		if ($mess2) {
		    $proc->msg($mess . ' # contained inside...');
		    $proc->msg($mess2);
		    return;
		}
		$proc->msg($mess);
	    }
	    return;
	} elsif (scalar @args == 1 and ($args[0]) =~ /^0x/) {
	    my $addr = $args[0];
	    my $coderef = \&$funcname;
	    my $info = $deparse->coderef2list($coderef);
	    my ($op_info, $mess) = show_addr($deparse, hex($addr));
	    if ($op_info) {
		my ($dummy, $mess2) = show_addr($deparse, $op_info->{parent});
		if ($mess2) {
		    $proc->msg($mess . ' # contained inside...');
		    $proc->msg($mess2);
		    return;
		}
		$proc->msg($mess);
	    } else {
		while (my($key, $value) = each %{$deparse->{optree}}) {
		    my $parent_op_name = 'undef';
		    if ($value->{parent}) {
			my $parent = $deparse->{optree}{$value->{parent}};
			$parent_op_name = $parent->{op}->name if $parent->{op};
		    }
		    printf("0x%x %s/%s of %s |\n%s",
			   $key, $value->{op}->name, $value->{type},
			   $parent_op_name, $deparse->indent_info($value));
		    printf " ## line %s\n", $value->{cop} ? $value->{cop}->line : 'undef';
		    print '-' x 30, "\n";
		}
		print join(', ', map sprintf("0x%x", $_), sort keys %{$deparse->{optree}}), "\n";
	    }
	} else {
	    my $deparse = B::DeparseTree->new('-p', '-l',  @options);
	    my @package_parts = split(/::/, $funcname);
	    my $prefix = '';
	    $prefix = join('::', @package_parts[0..scalar(@package_parts) - 1])
		if @package_parts;
	    my $short_func = $package_parts[-1];

	    $text = "package $prefix;\nsub $short_func" . $deparse->coderef2text(\&$funcname);
	}
    } else  {
	my $options = join(',', @options);
	my $cmd="$EXECUTABLE_NAME  -MO=Deparse,$options $filename";
	$text = `$cmd 2>&1`;
	if ($? >> 8 != 0) {
	    $proc->msg($text);
	    return;
	}
    };
  DONE:
    $text = Devel::Trepan::DB::LineCache::highlight_string($text) if $proc->{settings}{highlight};
    $proc->msg($text);

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
    $proc->{settings}{highlight} = undef;
    $cmd->run([$NAME]);
    print '-' x 30, "\n";
    $cmd->run([$NAME, '-l']);
    print '-' x 30, "\n";
    $proc->{frame}{fn} = 'run';
    $proc->{settings}{highlight} = 'dark';
    $cmd->run([$NAME]);
}

1;
