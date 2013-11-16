# Check that a watch expression changes from a given value to another
set basename on
set highlight off
set display eval dumper
# See that "info break" shows nothing.
info break
continue gcd
s
next
watch $a
# See that "info watch" shows something
info watch
break 14
c
s
list
# Se that break shows watch expression
info break
quit!
