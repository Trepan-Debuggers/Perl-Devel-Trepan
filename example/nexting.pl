#!/usr/bin/env perl
# For testing next, next+ next-, step+, step-, and set different;
sub p() { 
    return 5;
};

my $x=1; $x=2; 
$x = p() ; $x=3;
$x = 4;
