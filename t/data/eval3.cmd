# Test to caller is faked properly
# use with example/gcd.pl
set display eval dumper
set auto eval on
set max width 300
@ caller
c gcd
# Until debugger function-call handling is fixed
step
@ caller(0)
@ caller 1
quit
