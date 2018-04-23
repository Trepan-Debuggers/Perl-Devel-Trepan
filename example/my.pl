#!/usr/bin/env perl
use strict; use warnings;
my $a = 100;
sub bar($h) {
    return $h;
}

sub foo($a) {
    my @b = (1, "b");
    my %h = (1 =>'foo', 'food' => 'fight');
    bar \%h;
    our $c = scalar @b;
}
foo 5;
