# -*- coding: utf-8 -*-
# Copyright (C) 2011, 2012 Rocky Bernstein <rocky@cpan.org> 
use strict; use warnings;
use rlib '../../..';

package Devel::Trepan::CmdProcessor;
use English qw( -no_match_vars );

sub parse_next_step_suffix($$)
{
    my ($self, $step_cmd) = @_;
    my $opts = {};
    my $sigil = substr($step_cmd, -1);
    if ('-' eq $sigil) {
        $opts->{different_pos} = 0;
    } elsif ('+' eq $sigil) { 
        $opts->{different_pos} = 1;
    } elsif ('=' eq $sigil) { 
        $opts->{different_pos} = $self->{settings}{different}; 
        # when ('!') { $opts->{stop_events} = {'raise' => 1} };
        # when ('<') { $opts->{stop_events} = {'return' => 1}; }
        # when ('>') { 
        #     if (length($step_cmd) > 1 && substr($step_cmd, -2, 1) eq '<')  {
        #       $opts->{stop_events} = {'return' => 1 };
        #     } else {
        #       $opts->{stop_events} = {'call' => 1; }
        #     }
        # }
    } else {
        $opts->{different_pos} = $self->{settings}{different};
    }
    return $opts;
}

1;
