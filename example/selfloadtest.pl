#!/usr/bin/env perl
use rlib '../lib';
eval {use SelfLoader;};
use strict; use warnings;

package main;

unless (caller()) {
    printf "%d\n", F_Undo();
    # print $Devel::Trepan::SelfLoader::Cache{'main::F_Undo'};
}

__DATA__

sub F_Undo
{
    my $x = 1;
    my $y = 2;
    print "F_Undo called\n";
    return $x + $y;
}
