#!/usr/bin/env perl
# For testing next, next+ next-, step+, step-, and set different;
sub p() { 
    return 5;
};

my $x=1; my $y=2; 
$x=$y; $y = 4; $x += $y;
$x=6; $y = p(); my $z = p(); 
$x = 8 + $y + $z;
