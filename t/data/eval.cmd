# test of eval and bugs we once had.
# use with example/gcd.pl 3 5
set auto eval on
set display eval dumper
1 + 2
@ARGV
@ @ARGV
$ @ARGV
# An eval with no sigil. We once had a bug here
use English
eval 3+4
# Check that "my" variables can be evaluated properly
c gcd
s
$a
$b
# See that @_ is set properly.
@ @_
quit!
