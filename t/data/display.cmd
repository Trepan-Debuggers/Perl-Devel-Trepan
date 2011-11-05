# Test of display/undisplay debugger command
display join(", ", @ARGV)
step
undisplay a
undisplay 2
undisplay 1
step
display join(" | ", @ARGV)
step
undisplay
