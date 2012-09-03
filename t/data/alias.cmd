# Test of alias debugger command
set max width 80
alias yy foo
alias yy step
alias evd set display eval
evd dumper
alias evd
evd
evd dumper
alias evd set display eval dumper
evd
alias upper up
help up
unalias upper
help up
set auto eval off
upper
quit!

