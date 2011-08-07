# Copyright (C) 2011 Rocky Bernstein <rocky@cpan.org>
# classes to support communication to and from the debugger.  This
# communcation might be to/from another process or another computer.
# And reading may be from a debugger command script.
# 
# For example, we'd like to support Sockets, and serial lines and file
# reading, as well a readline-type input. Encryption and Authentication
# methods might decorate some of the communication channels.
# 
# Some ideas originiated as part of Matt Fleming's 2006 Google Summer of
# Code project.

use strict;
use Exporter;
use warnings;

package Trepan::IO::Base;

use vars qw(@EXPORT @EXPORT_OK);

my $DEFAULT_OPTS = {
    line_edit => 0,
};

my $opts;
    
sub new($$;$) {
    my($class, $input, $opts)  = @_;
    $opts      = $DEFAULT_OPTS.merge($opts);
    my $line_edit = $opts->{line_edit};
    my $self = {};
    $self->{input} = $input;
    $self->{line_edit} = $line_edit;
    bless $self, $class;
}

sub close($) {
    my($self) = @_;
    $self->{input}->close unless $self->{input}->is_closed;
}

sub is_eof($) {
    my($self) = @_;
    return $self->{input}->is_eof;
}

# Read a line of input. EOFError will be raised on EOF.  
#
#   Note that we don't support prompting first. Instead, arrange
#  to call Trepan::Output.write() first with the prompt. If
# `use_raw' is set raw_input() will be used in that is supported
#    by the specific input input. If this option is left None as is
#    normally expected the value from the class initialization is
#    used.
sub readline($) {
    my($self) = @_;
    $self->{input}->readline;
}

# # This is an abstract class that specifies debugger output.
# package Trepan::IO::OutputBase;

# use vars qw(@EXPORT @EXPORT_OK $output);

# sub new($;$) {
#     my($self) = @_;
#     $class, $output, $opts = @_;
#     my $self = {};
#     $self->{flush_after_write} = 0;
#     $self->{output} = $output;
#     $self->{eof} = 0;
#     bless $self, $class;
# }

# sub close($) {
#     my($self) = @_;
#     $self->{output}.close if $self->{output};
#     $self->{eof} = 1;
# }

# sub is_eof($) {
#     my($self) = @_;
#     return $self->{eof};
# }

# sub flush($) {
#     my($self) = @_;
#     $self->{output}.flush;
# }

# # Use this to set where to write to. output can be a 
# # file object or a string. This code raises IOError on error.
# sub write() {
#     my $self = shift;
#     $self->{output}.print(@_);
# }

# # used to write to a debugger that is connected to this
# # `str' written will have a newline added to it
# #
# sub writeline($$) {
#     my ($self, $msg) = @_;
#     $self->{output}.write(sprintf "%s\n", $msg);
# }

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
