# -*- coding: utf-8 -*-
# Copyright (C) 2011 Rocky Bernstein <rockyb@rubyforge.net>
# FIXME: Could combine manager code from breakpoints and display
use strict; use warnings; no warnings 'redefine';
use English;
use lib '../..';

use Class::Struct;
use strict;

struct DBDisplay => {
    number      => '$', # breakpoint/action number 
    enabled     => '$', # True if breakpoint or action is enabled
    arg         => '$', # What to display
    fmt         => '$'  # Format to use in display
};

package DBDisplay;
sub inspect($)
{
    my $self = shift;
    sprintf("number %s, enabled: %d, fmt: %s, arg: %s",
	    $self->number, $self->enabled, $self->fmt, $self->arg);
};


package Devel::Trepan::DisplayMgr;

sub new($$) 
{
    my ($class,$dbgr) = @_;
    my $self = {max => 0};
    $self->{dbgr} = $dbgr;
    bless $self, $class;
    $self->clear();
    $self;
}

sub clear($) 
{
    my $self = shift;
    $self->{list} = [];
    $self->{next_id} = 1;
}    

sub inspect($) 
{
    my $self = shift;
    my $str = '';
    for my $display (@{$self->{list}}) {
	next unless defined $display;
	$str .= $display->inspect . "\n";
    }
    $str;
}    

# Remove all breakpoints that we have recorded
sub DESTROY() {
    my $self = shift;
    for my $disp (@{$self->{list}}) {
        $self->delete_by_display($disp) if defined($disp);
    }
    $self->{clear};
}

sub find($$)
{
    my ($self, $index) = @_;
    for my $display (@{$self->{list}}) {
	next unless $display;
	return $display if $display->number eq $index;
    }
    return undef;
}

sub delete($$)
{
    my ($self, $index) = @_;
    my $display = $self->find($index);
    if (defined ($display)) {
        $self->delete_by_display($display);
        return $display;
    } else {
        return undef;
    }
}

sub delete_by_display($$)
{
    my ($self, $delete_display) = @_;
    for my $candidate (@{$self->{list}}) {
	next unless defined $candidate;
	if ($candidate eq $delete_display) {
	    $candidate = undef;
	    return $delete_display;
	}
    }
    return undef;
}

sub add($$)
{
    my ($self, $display) = @_;
    $self->{max}++;
    my $number = $self->{max};
    my $disp = DBDisplay->new(
	number=>$number, enabled => 1, arg => $display, fmt => '$');
    push @{$self->{list}}, $disp;
    return $disp;
}

sub compact($)
{
    my $self = shift;
    my @new_list = ();
    for my $display (@{$self->{list}}) {
	next unless defined $display;
	push @new_list, $display;
    }
    $self->{list} = \@new_list;
    return $self->{list};
}

sub is_empty($)
{
    my $self = shift;
    $self->compact();
    return scalar(0 == @{$self->{list}});
}

sub max($)
{
    my $self = shift;
    my $max = 0;
    for my $display (@{$self->{list}}) {
	$max = $display->number if $display->number > $max;
    }
    return $max;
}

sub size($)
{
    my $self = shift;
    $self->compact();
    return scalar @{$self->{list}};
}

sub reset($)
{
    my $self = shift;
    $self->{list} = [];
}


unless (caller) {

    sub display_status($$)
    { 
	my ($displays, $i) = @_;
	printf "list size: %s\n", $displays->size();
	printf "max: %d\n", $displays->max() // -1;
	print $displays->inspect();
	print "--- ${i} ---\n";
    }

require Devel::Trepan::Core;
my $dbgr = Devel::Trepan::Core->new;
my $displays = Devel::Trepan::DisplayMgr->new($dbgr);
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



  # p displays.delete(2)
  # p displays[2]
  # display_status(displays, 3)

  # # Two of the same breakpoints but delete 1 and see that the
  # # other still stays
  # offset = frame.pc_offset
  # b2 = Trepan::Breakpoint.new(iseq, offset)
  # displays << b2
  # display_status(displays, 4)
  # b3 = Trepan::Breakpoint.new(iseq, offset)
  # displays << b3
  # display_status(displays, 5)
  # displays.delete_by_display(b2)
  # display_status(displays, 6)
  # displays.delete_by_display(b3)
  # display_status(displays, 7)
}

1;
