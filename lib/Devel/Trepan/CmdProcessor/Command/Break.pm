# -*- coding: utf-8 -*-
# Copyright (C) 2011 Rocky Bernstein <rocky@cpan.org>
use warnings; no warnings 'redefine';
use rlib '../../../..';

use Devel::Trepan::DB::LineCache;
use Devel::Trepan::DB::Sub;
# require_relative '../../app/condition'

package Devel::Trepan::CmdProcessor::Command::Break;
use English qw( -no_match_vars );
use if !@ISA, Devel::Trepan::CmdProcessor::Command;
unless (@ISA) {
    eval <<'EOE';
    use constant ALIASES    => qw(b);
    use constant CATEGORY   => 'breakpoints';
    use constant SHORT_HELP => 'Set a breakpoint';
    use constant MIN_ARGS  => 0;   # Need at least this many
    use constant MAX_ARGS  => undef;  # Need at most this many - undef -> unlimited.
    use constant NEED_STACK => 0;
EOE
}

use strict; use vars qw(@ISA); @ISA = @CMD_ISA;
use vars @CMD_VARS;  # Value inherited from parent

our $NAME = set_name();
our $HELP = <<"HELP";
${NAME} [LOCATION] [if CONDITION]

Set a breakpoint. If no location is given use the current stopping
point.

Examples:
   ${NAME}                  # set a breakpoint on the current line
   ${NAME} gcd              # set a breakpoint in function gcd
   ${NAME} gcd if \$a == 1   # set a breakpoint in function gcd with 
                          # condition \$a == 1
   ${NAME} 10               # set breakpoint on line 10

See also "tbreak", "delete", "info break" and "condition".
HELP

# FIXME: Should we include all files? 
# Combine with LIST completion.
sub complete($$)
{
    my ($self, $prefix) = @_;
    my $filename = $self->{proc}->filename;
    my @completions = sort(('.', DB::LineCache::file_list, DB::subs,
			    DB::LineCache::trace_line_numbers($filename)));
    Devel::Trepan::Complete::complete_token(\@completions, $prefix);
}

#  include Trepan::Condition

# This method runs the command
sub run($$) {
    my ($self, $args) = @_;
    my @args = @$args;
    shift @args;
    my $proc = $self->{proc};
    my $bp;
    my $arg_count = scalar @args;
    if ($arg_count == 0) {
	$bp = $self->{dbgr}->set_break($DB::filename, $DB::lineno);
    } else {
	my ($filename, $line_or_fn, $condition);
	if ($arg_count > 2) {
	    if ($args[0] eq 'if') {
		$line_or_fn = $DB::lineno;
		$filename = $DB::filename;
		unshift @args, $line_or_fn;
	    } else  {
		$filename = $args[0];
		if ($args[1] =~ /\d+/) {
		    $line_or_fn = $args[1];
		    shift @args;
		} elsif ($args[1] eq 'if') {
		    $line_or_fn = $args[0];
		} else {
		    $line_or_fn = $args[0];
		}
	    }
	} else {
	    # $arg_count == 1. 
	    $line_or_fn = $args[0];
	    if ($line_or_fn =~ /^\d+/) {
		$filename = $DB::filename;
	    } else {
		my @matches = $self->{dbgr}->subs($args[0]);
		if (scalar(@matches) == 1) {
		    $filename = $matches[0][0];
		} else {
		    my $canonic_name = DB::LineCache::map_file($args[0]);
		    if (DB::LineCache::is_cached($canonic_name)) {
			$filename = $canonic_name;
		    }
		}
	    }
	    if ($arg_count == 2 && $args[1] =~ /\d+/) {
		$line_or_fn = $args[1];
		shift @args;
	    }
	}
	shift @args;
	if (scalar @args) {
	    if ($args[0] eq 'if') {
		shift @args;
		$condition = join(' ', @args);
	    } else {
		$proc->errmsg("Expecting 'if' to start breakpoint condition;" . 
			      " got ${args[0]}");
	    }
	}
	my $msg = $self->{dbgr}->break_invalid($filename, $line_or_fn);
	my $force = 0;
	if ($msg) {
	    if ($msg =~ /not known to be a trace line/) {
		$proc->errmsg($msg);
		$proc->msg("Use 'info file $filename brkpts' to see breakpoints I know about");
		$force = $self->{proc}->confirm('Set breakpoint anyway?', 0);
		return unless $force;
	    }
	}
	$bp = $self->{dbgr}->set_break($filename, $line_or_fn, 
				       $condition, undef, undef, undef, $force);
    }
    if (defined($bp)) {
	    my $prefix = $bp->type eq 'tbrkpt' ? 
		'Temporary breakpoint' : 'Breakpoint' ;
	    my $id = $bp->id;
	    my $filename = $proc->canonic_file($bp->filename);
	    my $line_num = $bp->line_num;
	    $proc->{brkpts}->add($bp);
	    $proc->msg("$prefix $id set in $filename at line $line_num");
	    # Warn if we are setting a breakpoint on a line that starts
	    # "use.."
	    my $text = DB::LineCache::getline($bp->filename, $line_num, 
					      {output => 'plain'});
	    if (defined($text) && $text =~ /^\s*use\s+/) {
		$proc->msg("Warning: 'use' statements get evaluated at compile time... You may have already passed this statement.");
	    }
    }
}

unless (caller) {
    # require Devel::Trepan::Core;
    # my $db = Devel::Trepan::Core->new;
    # my $intf = Devel::Trepan::Interface::User->new;
    # my $proc = Devel::Trepan::CmdProcessor->new([$intf], $db);
    # $proc->{stack_size} = 0;
    # my $cmd = __PACKAGE__->new($proc);
    # $DB::single = 1;
    # $cmd->run([$NAME, __LINE__]);
    # my $cmd = __PACKAGE__->new($proc);
    # $cmd->run([$NAME]);
}

1;
