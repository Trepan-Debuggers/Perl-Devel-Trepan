# Make sure we skip over deleted breakpoints in list,
# but still catch breakpoints in place.
set basename on
set highlight off
continue gcd
list
break gcd
list . 
step 
list
quit!
