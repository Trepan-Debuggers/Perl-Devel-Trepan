#!/usr/bin/env perl
use SelfLoader;
use strict; use warnings;

printf "%d\n", F_Undo();
F_Also();

__DATA__

sub F_Undo
{
    my $x = 1;
    my $y = 2;
    print "F_Undo called\n";
    return $x + $y;
}

sub F_Also
{
    print "That's all!\n";
}
