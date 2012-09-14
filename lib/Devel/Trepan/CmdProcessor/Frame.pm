# -*- coding: utf-8 -*-
# Copyright (C) 2011, 2012 Rocky Bernstein <rocky@cpan.org> 
use strict; use warnings;
use rlib '../../..';
use Devel::Trepan::DB::LineCache; # for map_file
use Devel::Trepan::Complete;

package Devel::Trepan::CmdProcessor;
use English qw( -no_match_vars );

sub adjust_frame($$$)
{
    my ($self, $frame_num, $absolute_pos) = @_;
    my $frame;
    ($frame, $frame_num) = $self->get_frame($frame_num, $absolute_pos);
    if ($frame) {
        $self->{frame} = $frame;
        $self->{frame_index} = $frame_num;
        unless ($self->{settings}{traceprint}) {
            my $opts = {
                basename    => $self->{settings}{basename},
                current_pos => $frame_num,
                maxwidth    => $self->{settings}{maxwidth},
            };
            $self->print_stack_trace_from_to($frame_num, $frame_num, $self->{frames}, $opts);
            $self->print_location ;
        }
        $self->{list_line} = $self->line();
        $self->{list_filename} = $self->filename();
        $self->{frame};
    } else {
        undef
    }
}

sub frame_complete($$;$)
{
    my ($self, $prefix, $direction) = @_;
    $direction = 1 unless defined $direction;
    my ($low, $high) = $self->frame_low_high($direction);
    my @ary = ($low..$high);
    Devel::Trepan::Complete::complete_token(\@ary, $prefix);
}

sub frame_low_high($;$)
{
    my ($self, $direction) = @_;
    $direction = 1 unless defined $direction;
    my $stack_size = $self->{stack_size};
    my ($low, $high) = (-$stack_size, $stack_size-1);
    ($low, $high) = ($high, $low) if ($direction < 0);
    return ($low, $high);
}

sub frame_setup($$)
{
    my ($self, $frame_aref) = @_;
    
    if (defined $frame_aref) {
        $self->{frames} = $frame_aref;
        $self->{stack_size}    = $#{$self->{frames}}+1;
    } else {
        ### FIXME: look go over this code.
        my $stack_size = $DB::stack_depth;
        my $i=0;
        my @frames = $self->{dbgr}->backtrace(0);
        @frames = splice(@frames, 2) if $self->{dbgr}{caught_signal};

        if ($self->{event} eq 'post-mortem') {
            $stack_size = 0;
            for my $frame (@frames) {
                next unless defined($frame) && exists($frame->{file});
                $stack_size ++;
            }
        } else {
            while (my ($pkg, $file, $line, $fn) = caller($i++)) {
                last if 'DB::DB' eq $fn or ('DB' eq $pkg && 'DB' eq $fn);
            } 
            if ($stack_size <= 0) {
                # Dynamic debugging didn't set $DB::stack_depth correctly.
                my $j=$i;
                while (caller($j++)) {
                    $stack_size++;
                }
                $stack_size++;
                $DB::stack_depth = $j;
            } else {
                $stack_size -= ($i-3);
            }
        }
        $self->{frames} = \@frames;
        $self->{stack_size}    = $stack_size;
    }

    $self->{frame_index}   = 0;
    $self->{hide_level}    = 0;
    $self->{frame}         = $self->{frames}[0];
    $self->{list_line}     = $self->line();
    $self->{list_filename} = $self->filename();
}

sub filename($)
{
    my $self = shift;
    DB::LineCache::map_file($self->{frame}{file});
}

sub funcname($)
{
    my $self = shift;
    $self->{frame}{fn};
}

sub get_frame($$$) 
{
    my ($self, $frame_num, $absolute_pos) = @_;
    my $stack_size = $self->{stack_size};

    if ($absolute_pos) {
        $frame_num += $stack_size if $frame_num < 0;
    } else {
        $frame_num += $self->{frame_index};
    }

    if ($frame_num < 0) {
        $self->errmsg('Adjusting would put us beyond the newest frame.');
        return (undef, undef);
    } elsif ($frame_num >= $stack_size) {
        $self->errmsg('Adjusting would put us beyond the oldest frame.');
        return (undef, undef);
    }

    my $frames = $self->{frames};
    unless ($frames->[$frame_num]) {
        my @new_frames = $self->{dbgr}->backtrace(0);
        $self->{frames}[$frame_num] = $new_frames[$frame_num];
    }
    $self->{frame} = $frames->[$frame_num];
    return ($self->{frame}, $frame_num);
}

sub line($)
{
    my $self = shift;
    $self->{frame}{line};
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
