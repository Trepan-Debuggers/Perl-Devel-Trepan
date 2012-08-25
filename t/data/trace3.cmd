# Test "set trace print" with "step" and "continue"
# use with gcd.pl 3 5
set trace print on
break 11
step
continue
step
step
disable 1
finish
quit!
