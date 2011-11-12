# -*- coding: utf-8 -*-
# Copyright (C) 2011 Rocky Bernstein <rockyb@rubyforge.net>
use strict; use warnings; no warnings 'redefine';
use English qw( -no_match_vars );
use rlib '../..';

use Class::Struct;
use strict;

struct WatchPoint => {
    id          => '$', # watchpoint number
    enabled     => '$', # True if watchpoint is enabled
    hits        => '$', # How many times watch was hit
    expr        => '$', # what Perl expression to evaluate
    old_value   => '$', # Previous value
    current_val => '$', # Current value. Set only when != old value
};

package WatchPoint;
sub inspect($)
{
    my $self = shift;
    sprintf("watchpoint %d, expr %s, old_value: %s, current_value %s",
	    $self->id, $self->expr, $self->old_value // 'undef',
	    $self->current_val // 'undef',
	);
};

package Devel::Trepan::WatchMgr;

sub new($$) 
{
    my ($class,$dbgr) = @_;
    my $self = {};
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
    for my $watchpoint ($self->list) {
	next unless defined $watchpoint;
	$str .= $watchpoint->inspect . "\n";
    }
    $str;
}    

sub list($)
{
    my $self = shift;
    return @{$self->{list}};
    
}

# Remove all breakpoints that we have recorded
sub DESTROY() {
    my $self = shift;
    for my $id ($self->list) {
        $self->delete_by_object($id) if defined($id);
    }
    $self->{clear};
}

sub find($$)
{
    my ($self, $index) = @_;
    for my $object ($self->list) {
	next unless $object;
	return $object if $object->id eq $index;
    }
    return undef;
}

sub delete($$)
{
    my ($self, $index) = @_;
    my $object = $self->find($index);
    if (defined ($object)) {
        $self->delete_by_object($object);
        return $object;
    } else {
        return undef;
    }
}

sub delete_by_object($$)
{
    my ($self, $delete_object) = @_;
    for my $candidate ($self->list) {
	next unless defined $candidate;
	if ($candidate eq $delete_object) {
	    $candidate = undef;
	    return $delete_object;
	}
    }
    return undef;
}

sub add($$)
{
    my ($self, $expr) = @_;
    my $watchpoint = WatchPoint->new(
        id       => $self->{next_id}++,
	enabled => 1,
	hits    => 0,
	expr    => $expr, 
	);
	
    push @{$self->{list}}, $watchpoint;
    return $watchpoint;
}

sub compact($)
{
    my $self = shift;
    my @new_list = ();
    for my $watchpoint ($self->list) {
	next unless defined $watchpoint;
	push @new_list, $watchpoint;
    }
    $self->{list} = \@new_list;
    return $self->{list};
}

sub is_empty($)
{
    my $self = shift;
    $self->compact();
    return scalar(0 == $self->list);
}

sub max($)
{
    my $self = shift;
    my $max = 0;
    for my $watchpoint ($self->list) {
	$max = $watchpoint->id if $watchpoint->id > $max;
    }
    return $max;
}

sub size($)
{
    my $self = shift;
    $self->compact();
    return scalar $self->list;
}

sub reset($)
{
    my $self = shift;
    for my $id ($self->list) {
     	$self->{dbgr}->delete_object($id);
     }
    $self->{list} = [];
}


unless (caller) {

    sub wp_status($$)
    { 
	my ($watchpoints, $i) = @_;
	printf "list size: %s\n", $watchpoints->size();
	printf "max: %d\n", $watchpoints->max() // -1;
	print $watchpoints->inspect();
	print "--- ${i} ---\n";
    }

# require Devel::Trepan::Core;
# my $dbgr = Devel::Trepan::Core->new;
my $watchpoints = Devel::Trepan::WatchMgr->new('bogus');
wp_status($watchpoints, 0);

my $watchpoint1 = $watchpoints->add('1+2');
wp_status($watchpoints, 1);
$watchpoints->add('3*4');
wp_status($watchpoints, 2);

$watchpoints->delete_by_object($watchpoint1);
wp_status($watchpoints, 3);

$watchpoints->add('3*4+5');
wp_status($watchpoints, 4);



  # p watchpoints.delete(2)
  # p watchpoints[2]
  # wp_status(watchpoints, 3)

  # # Two of the same breakpoints but delete 1 and see that the
  # # other still stays
  # offset = frame.pc_offset
  # b2 = Trepan::Breakpoint.new(iseq, offset)
  # watchpoints << b2
  # wp_status(watchpoints, 4)
  # b3 = Trepan::Breakpoint.new(iseq, offset)
  # watchpoints << b3
  # wp_status(watchpoints, 5)
  # watchpoints.delete_by_object(b2)
  # wp_status(watchpoints, 6)
  # watchpoints.delete_by_object(b3)
  # wp_status(watchpoints, 7)
}

1;
