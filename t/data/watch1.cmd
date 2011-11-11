# Check that a watch expression changes from a given value to another
set basename on
set highlight off
continue gcd
next
watch $a
break 14
c 
list
quit!
