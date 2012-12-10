#!/usr/bin/env perl
# For testing next, next+ next-, step+, step-, and set different;
sub p() { 
    return 5;
};

# To have something to "step different" with.
my $x=1; my $y=2; 
$x=$y; $y = 4; $x += $y;
$x=6; $y = p(); my $z = p(); 

# To have something to "step" with
$x = 8;
$x += $y;
$x += $z;
$x += 5;
$x -= 5;

