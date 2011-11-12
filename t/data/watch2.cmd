# Look for bug where continue would
# ignore calls to DB::DB() and ignore
# watch expressions
set basename on
set highlight off
watch $a
continue
continue
continue
q!
