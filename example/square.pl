#!/usr/bin/env perl
# To show off multiple statements and stopping points per line.

my ($i, $sqr, $odd) = (0, 0, 1);
for ($i=0; $i<4; $i++) {
    $sqr += $odd; $odd += 2
}
print "sqr($i) = $sqr\n";
