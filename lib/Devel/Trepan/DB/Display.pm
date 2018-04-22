# -*- coding: utf-8 -*-
# Copyright (C) 2011-2013, 2018 Rocky Bernstein <rocky@cpan.org>
# FIXME: Could combine manager code from breakpoints and display
use strict; use warnings; no warnings 'redefine';
use English qw( -no_match_vars );

use Class::Struct;
use strict;

struct DBDisplay => {
    number      => '$', # display number
    enabled     => '$', # True if display is enabled
    arg         => '$', # What to display
    fmt         => '$', # Format to use in display
    return_type => '$'  # Kind of value expected in return
};

package DBDisplay;
sub inspect($self)
{
    sprintf("number %s, enabled: %d, fmt: %s, arg: %s",
            $self->number, $self->enabled, $self->fmt, $self->arg);
};


package Devel::Trepan::DB::DisplayMgr;

sub new($class, $dbgr)
{
    my $self = {max => 0};
    $self->{dbgr} = $dbgr;
    bless $self, $class;
    $self->clear();
    $self;
}

sub clear($self)
{
    $self->{list} = [];
    $self->{next_id} = 1;
}

sub inspect($self)
{
    my str $str = '';
    for my $display (@{$self->{list}}) {
        next unless defined $display;
        $str .= $display->inspect . "\n";
    }
    $str;
}

# Remove all breakpoints that we have recorded
sub DESTROY($self) {
    for my $disp (@{$self->{list}}) {
        $self->delete_by_display($disp) if defined($disp);
    }
    $self->{clear};
}

sub find($self, $index)
{
    for my $display (@{$self->{list}}) {
        next unless $display;
        return $display if $display->number eq $index;
    }
    return undef;
}

sub delete($self, $index)
{
    my $display = $self->find($index);
    if (defined ($display)) {
        $self->delete_by_display($display);
        return $display;
    } else {
        return undef;
    }
}

sub delete_by_display($self, $delete_display)
{
    for my $candidate (@{$self->{list}}) {
        next unless defined $candidate;
        if ($candidate eq $delete_display) {
            $candidate = undef;
            return $delete_display;
        }
    }
    return undef;
}

sub add
{
    my ($self, $display,$return_type) = @_;
    $self->{max}++;
    $return_type = '$' unless defined $return_type;
    my $number = $self->{max};
    my $disp = DBDisplay->new(
        number      => $number,
        enabled     => 1,
        arg         => $display,
        fmt         => '$',
        return_type => $return_type);
    push @{$self->{list}}, $disp;
    return $disp;
}

sub compact($self)
{
    my @new_list = ();
    for my $display (@{$self->{list}}) {
        next unless defined $display;
        push @new_list, $display;
    }
    $self->{list} = \@new_list;
    return $self->{list};
}

sub is_empty($self)
{
    $self->compact();
    return scalar(0 == @{$self->{list}});
}

sub find($self, $num)
{
    for my $display (@{$self->{list}}) {
        return $display if $display->number == $num;
    }
    return undef;
}

sub max($self)
{
    my int $max = 0;
    for my $display (@{$self->{list}}) {
        $max = $display->number if $display->number > $max;
    }
    return $max;
}

sub size($self)
{
    $self->compact();
    return scalar @{$self->{list}};
}

sub reset($self)
{
    $self->{list} = [];
}


unless (caller) {

    sub display_status($displays, $i)
    {
        printf "list size: %s\n", $displays->size();
        my $max = $displays->max();
        $max = -1 unless defined $max;
        printf "max: %d\n", $max;
        print $displays->inspect();
        print "--- ${i} ---\n";
    }

    eval "use rlib '..';";
    require Devel::Trepan::Core;
    my $dbgr = Devel::Trepan::Core->new;
    my $displays = Devel::Trepan::DB::DisplayMgr->new($dbgr);
    display_status($displays, 0);
    my $display1 = DBDisplay->new(
        number=>1, enabled => 1, arg => '$dbgr', fmt => '$'
    );

    $displays->add($display1);
    display_status($displays, 1);

    my $display2 = DBDisplay->new(
        number=>2, enabled => 0, arg => '$displays', fmt => '$'
    );
    $displays->add($display2);
    display_status($displays, 2);

    $displays->delete_by_display($display1);
    display_status($displays, 3);

    my $display3 = DBDisplay->new(
       number=>3, enabled => 1, arg => 'foo', fmt => '$'
    );
    $displays->add($display3);
    display_status($displays, 4);

}

1;
