# Test that $0 is set properly
set evaldisplay dumper
eval use File::Basename
eval basename($0)
q!
