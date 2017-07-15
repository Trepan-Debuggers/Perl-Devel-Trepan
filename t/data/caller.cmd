# Test that caller hides DB properly
# use with example/gcd.pl
set auto eval on
set display eval dumper
step
@x = caller()
@x = caller(0)
q!
