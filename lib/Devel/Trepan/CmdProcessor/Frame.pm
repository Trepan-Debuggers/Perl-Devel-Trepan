# -*- coding: utf-8 -*-
# Copyright (C) 2011, 2012 Rocky Bernstein <rocky@cpan.org> 
use strict; use warnings;
use rlib '../../..';
use Devel::Trepan::DB::LineCache; # for map_file
use Devel::Trepan::Complete;

package Devel::Trepan::CmdProcessor;
use English qw( -no_match_vars );

sub frame_complete($$;$)
{
    my ($self, $prefix, $direction) = @_;
    $direction = 1 unless defined $direction;
    my ($low, $high) = $self->frame_low_high($direction);
    my @ary = ($low..$high);
    Devel::Trepan::Complete::complete_token(\@ary, $prefix);
}

sub print_stack_entry()
{
    my ($self, $frame, $i, $prefix, $opts) = @_;
    $opts->{maxstack} = 1e9 unless defined $opts->{maxstack};
    # Set the separator so arrays print nice.
    local $LIST_SEPARATOR = ', ';

    # Get the file name.
    my $file = $self->canonic_file($frame->{file});
    $file = '??' unless defined $file;

    # Put in a filename header if short is off.
    $file = ($file eq '-e') ? $file : "file `$file'" unless $opts->{short};
    
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
    my $wa;
    if (exists($frame->{wantarray})) {
        $wa = "$frame->{wantarray} = ";
    } else {
        $not_last_frame = 0;
        $wa = '' ;
    }
    my $lineno = $frame->{line} || '??';
    if ($opts->{short}) {
        my $fn = $s; # @_ >= 4 ? $_[3] : $s;
        $self->msg("$wa$fn$args from $file:$lineno");
    } else {
        # Non-short report includes full names.
        # Lose the DB::DB hook call if frame is 0.
        my $call_str = $not_last_frame ? "$wa$s$args in " : '';
        my $prefix_call = "$prefix$call_str";
        my $file_line   = $file . " at line $lineno";
        
        if (length($prefix_call) + length($file_line) <= $opts->{maxwidth}) {
            $self->msg($prefix_call . $file_line);
        } else {
            $self->msg($prefix_call);
            $self->msg("\t" . $file_line);
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
