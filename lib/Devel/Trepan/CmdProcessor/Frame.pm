# -*- coding: utf-8 -*-
# Copyright (C) 2011 Rocky Bernstein <rocky@cpan.org> 
use strict;
use warnings;
use lib '../../..';

package Devel::Trepan::CmdProcessor;
use English;

sub frame_setup($$$)
{
    my ($self, $frame_ary) = @_;
    my ( $pkg, $file, $line, $subroutine, $hasargs,
	 $wantarray, $evaltext, $is_require, $hints, $bitmask, 
	 $hinthash
	) = @$frame_ary;
    $self->{frame} = {
	pkg => $pkg,
	file => $file,
	line => $line,
	subroutine => $subroutine,
	hasargs => $hasargs,
	wantarray => $wantarray,
	evaltext => $evaltext,
	is_require => $is_require,
	hints => $hints,
	bitmask => $bitmask,
	hinthash => $hinthash
    };

    # $self->{stack_size} = $stack_size;
    $self->{frame_index} = 0;
    $self->{hide_level} = 0;
}
sub filename($)
{
    my $self = shift;
    $self->{frame}->{filename};
}
sub line($)
{
    my $self = shift;
    $self->{frame}->{line};
}

sub print_stack_entry()
{
    my ($self, $frame, $i, $prefix, $opts) = @_;
    # Set the separator so arrays print nice.
    local $LIST_SEPARATOR = ', ';

    # Grab and stringify the arguments if they are there.
    my $args =
	defined $frame->{args}
    ? "(@{ $frame->{args} })"
	: '';
    
    # Shorten them up if $opts->{maxtrace} says they're too long.
    $args = ( substr $args, 0, $opts->{maxstack} - 3 ) . '...'
	if length $args > $opts->{maxstack};
    
    # Get the file name.
    my $file = $frame->{file};

    # Put in a filename header if short is off.
    $file = ($file eq '-e') ? $file : "file `$file'" unless $opts->{short};
    
    # Get the actual sub's name, and shorten to $maxtrace's requirement.
    my $s = $frame->{fn};
    $s = ( substr $s, 0, $opts->{maxstack} - 3 ) . '...' 
	if length($s) > $opts->{maxstack};
    
    # Short report uses trimmed file and sub names.
    my $wa = $frame->{wantarray};
    if ($opts->{short}) {
	my $fn = $s; # @_ >= 4 ? $_[3] : $s;
	$self->msg("$wa=$fn$args from $file:$frame->{line}");
    } else {
	# Non-short report includes full names.
	$self->msg("$frame->{wantarray} = $s$args"
		   . " called from $file"
		   . " line $frame->{line}");
    }
}
    
sub print_stack_trace_from_to($$$$$) 
{
    my ($self, $from, $to, $frames, $opts) = @_;
    for (my $i=$from; $i <= $to; $i++) {
	my $prefix = '   '; # ($i == $opts->{current_pos}) ? '-->' : '   ';
	$prefix .= sprintf ' #%d ', $i;
	$self->print_stack_entry($frames->[$i], $i, $prefix, $opts);
    }
}    

# Print `count' frame entries
sub print_stack_trace($$$)
{ 
    my ($self, $frame, $opts)=@_;
    $opts ||= {maxstack=>1e9, count=>1e9};
    # $opts  = DEFAULT_STACK_TRACE_SETTINGS.merge(opts);
    my $halfstack = $opts->{maxstack} / 2;
    my $n         = scalar @{$frame};
    $n            = $opts->{count} if $opts->{count} < $n;
    if ($n > ($halfstack * 2)) {
        $self->print_stack_trace_from_to(0, $halfstack-1, $frame, $opts);
	my $msg = sprintf "... %d levels ...",  ($n - $halfstack*2);
        $self->msg($msg);
	$self->print_stack_trace_from_to($n - $halfstack, $n-1, $frame, $opts);
    } else {
	$self->print_stack_trace_from_to(0, $n-1, $frame, $opts);
    }
}
1;
