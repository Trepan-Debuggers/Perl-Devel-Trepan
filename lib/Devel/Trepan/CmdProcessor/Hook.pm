# -*- coding: utf-8 -*-
# Copyright (C) 2011 Rocky Bernstein <rocky@cpan.org> 
use strict; use warnings;
use lib '../../..';

use Class::Struct;
use Time::HiRes;

struct CmdProcessorHook => {
    priority    => '$',
    name        => '$',
    fn          => '$'
};


package Devel::Trepan::CmdProcessor::Hook;
#  attr_accessor :list

sub new($;$)
{    
    my ($class, $list) = @_;
    my $self = {};
    $list //= [];
    $self->{list} = $list;
    bless $self, $class;
    $self;
}

sub delete_by_name($)
{
    my ($self, $delete_name) = @_;
    my @new_list = ();
    for my $elt (@{$self->{list}}) {
	push(@new_list, $elt) unless $elt->name eq $delete_name;
    }
    $self->{list} = \@new_list;
}

sub is_empty($)
{
    my $self = shift;
    return 0 == scalar(@{$self->{list}});
}

sub insert($$$$)
{
    my ($self, $priority, $name, $hook) = @_;
    my $insert_loc;
    my @list = $self->{list};
    for ($insert_loc=0; $insert_loc < $#list; $insert_loc++) {
	my $entry = $self->{list}->[$insert_loc];
	if ($priority > $entry->priority) {
	    last;
	}
    }
    my $new_item = CmdProcessorHook->new(name => $name, priority=>$priority, fn => $hook);
    splice(@{$self->{list}}, $insert_loc, 0, $new_item);
}

sub insert_if_new($$$$)
{ 
    my ($self, $priority, $name, $hook) = @_;
    my $found = 0;
    for my $item (@{$self->{list}}) {
	if ($item->name eq $name) {
	    $found = 1;
	    last;
	}
    }
    $self->insert($priority, $name, $hook) unless ($found);
}

# Run each function in `hooks' with args
sub run($)
{
    my $self = shift;
    for my $hook (@{$self->{list}}) {
	$hook->fn->($hook->name, \@_);
    }
}

package Devel::Trepan::CmdProcessor;

# # Command processor hooks.
# attr_reader   :autolist_hook
# attr_reader   :timer_hook
# attr_reader   :trace_hook
# attr_reader   :tracebuf_hook
# attr_reader   :unconditional_prehooks
# attr_reader   :cmdloop_posthooks
# attr_reader   :cmdloop_prehooks

# # Used to time how long a debugger action takes
# attr_accessor :time_last

sub hook_initialize($)
{
    my ($self) = @_;
    my $commands = $self->{commands};
    $self->{cmdloop_posthooks}      = Devel::Trepan::CmdProcessor::Hook->new;
    $self->{cmdloop_prehooks}       = Devel::Trepan::CmdProcessor::Hook->new;
    $self->{unconditional_prehooks} = Devel::Trepan::CmdProcessor::Hook->new;

    my $list_cmd = $commands->{'list'};
    $self->{autolist_hook}  = ['autolist', 
			       sub{ $list_cmd->run(['list']) if $list_cmd}];
    
    $self->{timer_hook}     = ['timer', 
			       sub{
				   my $now = Time::HiRes::time;
				   $self->{time_last} //= $now;
				   my $mess = sprintf("%g seconds", $now - $self->{time_last});
				   $self->msg($mess);
				   $self->{time_last} = $now;
			       }];
    $self->{timer_posthook} = ['timer', 
			       sub{
				   $self->{time_last} = Time::HiRes::time}];
    $self->{trace_hook}     = ['trace', 
			       sub{ $self->print_location}];
    $self->{tracebuf_hook}  = ['tracebuffer', 
			       sub{
				   push(@{$self->{eventbuf}},
					($self->{event}, $self->{frame}));
			       }];
}

unless (caller) {
    # Demo it.
    my $hooks = Devel::Trepan::CmdProcessor::Hook->new();
    $hooks->run(5);
    my $hook1 = sub($$) { 
	my ($name, $a) = @_;
	my $args = join(', ', @$a);
	print "${name} called with $args\n";
    };
    $hooks = Devel::Trepan::CmdProcessor::Hook->new();
    $hooks->insert(-1, 'hook1', $hook1);
    $hooks->insert_if_new(-1, 'hook1', $hook1);
    my $dash_line = '-' x 30 . "\n";
    print $dash_line;
    print join(', ', @{$hooks->{list}}), "\n";
    $hooks->run(10);
    print $dash_line;
    $hooks->insert(-1, 'hook2', $hook1);
    $hooks->run(20);
    print $dash_line;
    $hooks->delete_by_name('hook2');
    $hooks->run(30);
    print $dash_line;
    $hooks->delete_by_name('hook1');
    $hooks->run(30);
    print $dash_line;
}

1;
