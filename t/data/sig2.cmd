# use with example/signal.pl
# See that we can stop on a signal properly
set autoeval on
c 10
handle HUP stop print
c
step
step
$leave_loop=1
continue
