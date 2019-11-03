# -*- coding: utf-8 -*-
# Copyright (C) 2014 Rocky Bernstein <rocky@cpan.org>
# Debugger Input/Output FIFO base Interface.

use warnings; use strict;

use rlib '../../..';

# Debugger Client Input/Output Socket.
package Devel::Trepan::IO::FIFOBase;

# Closes server connection.
# FIXME dry with FIFOClient by making a common FIFO routine
sub close
{
    my $self = shift;
    $self->{state} = 'closing';
    foreach my $FIFO ( $self->{input_name}, $self->{output_name} ) {
        close($FIFO);
    }
    $self->{state} = 'uninit';
    $self->{input} = $self->{output} = undef;
    print {$self->{logger}} "Disconnected\n" if $self->{logger};
}


sub is_disconnected($)
{
    my $self = shift;
    return 'disconnected' eq $self->{state};
}

sub autoflush {
    my ($self, $fh) = @_;
    my $o = select($fh);
    $|++;
    select($o);
}

sub have_term_readline($)
{
    return 0;
}

1;
