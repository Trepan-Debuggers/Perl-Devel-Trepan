# -*- coding: utf-8 -*-
# Copyright (C) 2011 Rocky Bernstein <rocky@cpan.org>

# Simulate I/O using lists of strings.

package Devel::Trepan::IO::StringArrayInput;
use warnings; use strict;

use lib '../../..';
use Devel::Trepan::IO;

use vars qw(@ISA);
@ISA = qw(Devel::Trepan::IO::InputBase);

# Simulate I/O using an array of strings. Sort of like StringIO, but
# even simplier.

sub new($$;$)
{
    my ($class, $inp, $opts) = @_;
    $opts //={};
    my $self = Devel::Trepan::IO::InputBase->new($inp, $opts);
    $self->{closed} = 0;
    bless $self, $class;
    $self
}

# this close() interface is defined for class compatibility
sub close($) 
{
    my $self = shift;
    $self->{closed} = 1;
}

sub is_closed($) 
{
    my $self = shift;
    $self->{closed};
}

sub is_eof($) 
{
    my $self = shift;
    $self->{closed} || !@{$self->{input}};
}

# Nothing to do here. Interface is for compatibility
sub flush($) { ; }

# Read a line of input. undef is returned on EOF.  
# Note that we don't support prompting.
sub readline($)
{
    my $self = shift;
    return undef if $self->is_eof;
    unless (@{$self->{input}}) {
	return undef;
    }
    my $line = shift @{$self->{input}};
    return $line ;
  }

#   class << self
#     # Use this to set where to read from.
#     sub open(inp, opts={})
#       if inp.is_a?(Array)
#         return self.new(inp)
#       else
#         raise IOError, "Invalid input type (%s) for %s" % [inp.class, inp]
#       }
#     }
#   }
# }

# Simulate I/O using an array of strings. Sort of like StringIO, but
# even simplier.
package Devel::Trepan::IO::StringArrayOutput;
use vars qw(@ISA);
@ISA = qw(Devel::Trepan::IO::OutputBase);

sub new
{
    my ($class, $out, $opts) = @_;
    $out //=[]; $opts //= {};
    my $self = Devel::Trepan::IO::OutputBase->new($out, $opts);
    $self->{closed} = 0;
    bless $self, $class;
    return $self;
}

# Nothing to do here. Interface is for compatibility
sub close($)
{
    my $self = shift;
    $self->{closed} = 1;
}

sub is_closed($)
{
    my $self = shift;
    $self->{closed};
  }

sub is_eof()
{
    my $self = shift;
    $self->{close} || !$self->{output};
}

# Nothing to do here. Interface is for compatibility
sub flush() { ; }

# This method the debugger uses to write. In contrast to
# writeline, no newline is added to the } to `str'.
#
sub write($$)
{
    my ($self, $msg) = @_;
    return undef if $self->{closed};
    push @{$self->{output}}, $msg;
}
  
# used to write to a debugger that is connected to this
# server; Here, we use the null string '' as an indicator of a
# newline.
sub writeline($$)
{
    my ($self, $msg) = @_;
    $self->write($msg);
    $self->write('');
}

#   class << self
#     # Use this to set where to write to. output can be a 
#     # file object or a string. This code raises IOError on error.
#     # 
#     # If another file was previously open upon calling this open,
#     # that will be stacked and will come back into use after
#     # a close_write().
#     sub open(output=[])
#       if output.is_a?(Array)
#         return self.new(output)
#       else
#         raise IOError, ("Invalid output type (%s) for %s" % 
#                         [output.class, output])
#       }
#     }
#   }
# }

# Demo
unless (caller) {
  my $inp = Devel::Trepan::IO::StringArrayInput->new(
      ['Now is the time', 'for all good men']);
  my $line = $inp->readline;
  print $line, "\n";
  $line = $inp->readline;
  print $line, "\n";
  $line = $inp->readline;
  print "That's the end the line\n" unless defined $line;

  my $out = Devel::Trepan::IO::StringArrayOutput->new;
  $out->writeline("Some output");
  $out->writeline('Hello, world!');
  print $out->{output}->[0], "\n";
  print $out->{output}->[1], "\n";
  print $out->{output}->[2], "\n";
#   out.write('Hello');
#   p out.output
#   out.writeline(', again.');
#   p out.output
# #     io.open_write(sys.stdout)
#   out.flush_after_write = true
#   out.write('Last hello')
#   print "Output is closed? #{out.closed?}"
#   out.close
#   p out.output
#   begin
#     out.writeline("You won't see me")
#   rescue
#   }

#   # Closing after already closed is okay
#   out.close
#   print "Output is closed? #{out.closed?}"
#   print "Input is closed? #{inp.closed?}"
#   inp.close
#   print "Input is closed? #{inp.closed?}"
}
