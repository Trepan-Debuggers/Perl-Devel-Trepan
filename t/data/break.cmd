# Use with example/gcd.pl
# Break without any args is at the position we are right now.
break
# Break on a function name
break gcd
break 11
# Try a break on a "use" statement to see that we get a warning.
break 3
delete 1
delete 2
info file . brkpts
# Test errors
break 10
break gcd1
continue gcd
quit!
