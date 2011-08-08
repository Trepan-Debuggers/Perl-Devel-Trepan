# # This is an abstract class that specifies debugger input output when
# # handled by the same channel, e.g. a socket or tty.
# #
# package Trepan::IO::InOutBase;
    
# sub initialize(inout, opts={}) {
#     @opts = DEFAULT_OPTS.merge(opts);
# @inout = inout
# }
    
# sub close {
#     @inout.close() if @inout;
# }
    
# sub is_eof() {
#     @input.is_eof
# }

# sub flush() {
#     @inout.flush
# }
    
# # Read a line of input. EOFError will be raised on EOF.  
# # 
# # Note that we don't support prompting first. Instead, arrange to
# # call DebuggerOutput.write() first with the prompt. If `use_raw'
# # is set raw_input() will be used in that is supported by the
# # specific input input. If this option is left nil as is normally
# # expected the value from the class initialization is used.
# sub readline(use_raw=nil) {
#     @input.readline;
# }

# # Use this to set where to write to. output can be a 
# # file object or a string. This code raises IOError on error.
# # 
# # Use this to set where to write to. output can be a 
# # file object or a string. This code raises IOError on error.
# sub write(*args) {
#     @inout.write(*args);
# }
    
# # used to write to a debugger that is connected to this
# # server; `str' written will have a newline added to it
# sub writeline( msg) {
#     @inout.write("%s\n" % msg);
# }

1;
