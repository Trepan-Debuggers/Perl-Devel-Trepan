# Test listing with breakpoints
set basename on
set highlight off
break 6
list
break 7
list 1
delete 1
list 1
tbreak 6
list 1
quit!



