# Test that $0 is set properly
set display eval dumper
eval use File::Basename
eval basename($0)
q!
