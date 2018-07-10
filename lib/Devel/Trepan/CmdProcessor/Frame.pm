# -*- coding: utf-8 -*-
# Copyright (C) 2011-2012, 2014-2015 Rocky Bernstein <rocky@cpan.org>
use strict; use warnings;
use rlib '../../..';
use Devel::Trepan::DB::LineCache; # for map_file and getline
use Devel::Trepan::Complete;

package Devel::Trepan::CmdProcessor;
use English qw( -no_match_vars );

my $have_deparse = eval q(use B::DeparseTree::Fragment; use Devel::Trepan::Deparse; 1);

sub frame_complete($$;$)
{
    my ($self, $prefix, $direction) = @_;
    $direction = 1 unless defined $direction;
    my ($low, $high) = $self->frame_low_high($direction);
    my @ary = ($low..$high);
    Devel::Trepan::Complete::complete_token(\@ary, $prefix);
}

sub print_stack_entry
{
    my ($self, $frame, $i, $prefix, $opts) = @_;
    $opts->{maxstack} = 1e9 unless defined $opts->{maxstack};
    # Set the separator so arrays print nice.
    local $LIST_SEPARATOR = ', ';

    # Get the file name.
    my $canonic_file = $self->canonic_file($frame->{file});
    $canonic_file = '??' unless defined $canonic_file;

    # Put in a filename header if short is off.
    my $file = ($canonic_file eq '-e') ? $canonic_file : "file `$canonic_file'" unless $opts->{short};

    my $not_last_frame = $i != ($self->{stack_size}-1);
    my $s = '';
    my $args =
        defined $frame->{args}
    ? "(@{ $frame->{args} })"
        : '';
    if ($not_last_frame) {
        # Grab and stringify the arguments if they are there.

        # Shorten them up if $opts->{maxwidth} says they're too long.
        $args = substr($args, 0, $opts->{maxwidth}-3) . '...'
            if length($args) > $opts->{maxwidth};

        # Get the actual sub's name, and shorten to $maxwidth's requirement.
        if (exists($frame->{fn})) {
            $s = $frame->{fn};
            $s = substr($s, 0, $opts->{maxwidth}-3) . '...'
                if length($s) > $opts->{maxwidth};
        }
    }

    # Short report uses trimmed file and sub names.
    my $want_array;
    if (exists($frame->{wantarray})) {
        $want_array = "$frame->{wantarray} = ";
    } else {
        $not_last_frame = 0;
        $want_array = '' ;
    }

    my $lineno = $frame->{line} || '??';
    my $addr = $opts->{displayop} && $frame->{addr} ? sprintf("0x%x ", $frame->{addr}) : '';
    if ($opts->{short}) {
        my $fn = $s; # @_ >= 4 ? $_[3] : $s;
	my $msg = sprintf("%s%s%s%s from %s:%d",
			  $want_array, $addr, $fn, $args, $file, $lineno);
        $self->msg($msg);
    } else {
        # Non-short report includes full names.
        # Lose the DB::DB hook call if frame is 0.
        my $call_str = $not_last_frame ? "$addr$want_array$s$args in " : $addr;
        my $prefix_call = "$prefix$call_str";
        my $file_line   = $file . " at line $lineno";

        if (length($prefix_call) + length($file_line) <= $opts->{maxwidth}) {
            $self->msg($prefix_call . $file_line);
        } else {
            $self->msg($prefix_call);
            $self->msg("\t" . $file_line);
        }
    }
    if ($opts->{source}) {
        my $line  = getline($canonic_file, $lineno, $opts);
        $self->msg($line) if $line;
    }


    if ($opts->{deparse} && $have_deparse && $addr) {
	my $funcname = $not_last_frame ? $frame->{fn} : "DB::DB";
	my $int_addr = $addr;
        $int_addr =~ s/\s+$//g;
	no warnings 'portable';
	$int_addr = hex($int_addr);
	my ($op_info) = deparse_offset($funcname, $int_addr);
	if ($op_info) {
	    if ($i != 0) {
		# All frames except the current frame we need to
		# back up the op_info;
		$op_info = get_prev_addr_info($op_info);
	    }
	    my $extract_texts = extract_node_info($op_info);
	    if ($extract_texts) {
		pmsg($self, join("\n", @$extract_texts))
	    } else {
		pmsg($self, $op_info->{text});
	    }
	}
    }

}

sub print_stack_trace_from_to($$$$$)
{
    my ($self, $from, $to, $frames, $opts) = @_;
    for (my $i=$from; $i <= $to; $i++) {
        my $prefix = ($i == $opts->{current_pos}) ? '-->' : '   ';
        $prefix .= sprintf ' #%d ', $i;
        $self->print_stack_entry($frames->[$i], $i, $prefix, $opts);
    }
}

# Print `count' frame entries
sub print_stack_trace($$$)
{
    my ($self, $frames, $opts)=@_;
    $opts ||= {maxstack=>1e9, count=>1e9};
    my $start = 0;
    my $n     = scalar @{$frames};
    my $halfstack = $opts->{maxstack} / 2;

    my $count = $opts->{count};
    if ($count < 0) {
	$start = $n + $count;
	$count = $n;
    } elsif ($count < $n) {
	$n = $count;
	$halfstack = $n;
    }

    # $opts  = DEFAULT_STACK_TRACE_SETTINGS.merge(opts);
    $n            = $count if $opts->{count} < $n;
    if ($n > ($halfstack * 2)) {
        $self->print_stack_trace_from_to($start, $halfstack-1, $frames, $opts);
        my $msg = sprintf "... %d levels ...",  ($n - $halfstack*2);
        $self->msg($msg);
        $self->print_stack_trace_from_to($n - $halfstack, $n-1, $frames, $opts);
    } else {
        $self->print_stack_trace_from_to($start, $n-1, $frames, $opts);
    }
}

1;
