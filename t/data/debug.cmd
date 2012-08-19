# Use with example/gcd.pl
set basename on
set highlight off
set autoeval on
set display eval dumper
# A should be undefined here.
$a
# First recursive debug
debug gcd(1,1)
step
step
# A and b are now defined
$a
$b
step
step
step
# Finished recusive debug $a is back on undef
$a
debug gcd(1,1)
s
s
$a
$b
# Try 2 levels of nested debugging.
debug gcd(2,2)
s
s
$a
s
s
s
# back to level 1
s
s
s
quit!
