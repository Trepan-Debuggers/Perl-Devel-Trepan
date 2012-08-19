# Test that __FILE__ and __LINE__ are set properly in eval.
set display eval dumper
eval __FILE__
eval __LINE__
q!
