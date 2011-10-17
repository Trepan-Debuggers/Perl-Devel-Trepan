# test of eval and bugs we once had.
set auto eval on
1 + 2
@ARGV
@ @ARGV
$ @ARGV
eval 3+4
# Check that "my" variables can be evaluated properly
c gcd
s
$a
$b
# See that @_ is set properly.
@ @_
quit!


