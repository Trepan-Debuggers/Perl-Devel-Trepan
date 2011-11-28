#!/usr/bin/env perl
use strict; use warnings;
our $a = 1;
sub bar($) {
    our $h = shift;
    return $h;
}

sub foo($) {
    our $a = shift;
    our @b = (1, "b");
    our %h = (1 =>'foo', 'food' => 'fight');
    bar \%h;
    our $c = scalar @b;
}
foo 5;
