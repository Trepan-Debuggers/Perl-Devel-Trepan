# Test "set auto list"
set basename on
set highlight off
set auto list on
step
step
step
# Try a command with a continuation character (\)
set auto list \
    off
step
step
quit!
