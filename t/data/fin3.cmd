# See that finish on a breakpoint line reports a "return" event
# not a breakpoint event. Line 21 the return location of gcd.
b 21
next 1
next 1
step
fin
info return
quit!





