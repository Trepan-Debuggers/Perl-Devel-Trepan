# Copyright (C) 2011, 2012 Rocky Bernstein <rocky@cpan.org>
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

use strict; use warnings;
use Exporter;
use rlib '../..';

package Devel::Trepan::IO::InputBase;
no warnings 'redefine';

use Devel::Trepan::Util qw(hash_merge);
# our @EXPORT;

my $DEFAULT_OPTS = {line_edit => 0};
# @EXPORT = qw(DEFAULT_OPTS);

sub new($$;$) {
    my($class, $input, $opts)  = @_;
    $opts ||= {};
    hash_merge($opts, $DEFAULT_OPTS);
    my $line_edit = $opts->{line_edit};
    my $self = {
	input     => $input,
	eof       => 0,
	line_edit => $line_edit
    };
    bless $self, $class;
    return $self;
}

sub is_closed($) {
    my($self) = shift;
    ! $self->{input} || $self->is_eof;
}

sub close($) {
    my($self) = shift;
    CORE::close $self->{input} unless $self->is_closed;
    $self->{eof} = 1;
}

sub want_term_readline() {
    0;
}

sub is_eof($) {
    my($self) = shift;
    return $self->{eof};
}

sub is_interactive() {
    0;
}

# This is an abstract class that specifies debugger output.
package Devel::Trepan::IO::OutputBase;

#    attr_accessor :flush_after_write
#    attr_reader   :output

sub new($$;$)
{
    my ($class, $out, $opts) = @_;
    $opts = {} unless defined $opts;

    my $self = {
	output => $out,
	flush_after_write => 0,
	eof               => 0
    };
    bless $self, $class;
    $self
}

sub close($)
{
    my $self = shift;
    $self->{output}->close if $self->{output};
    $self->{eof} = 1;
}

sub is_eof($) { $_->[0]->{eof} || $_->[0]->eof }

## sub flush($) { $_->[0]->{output}->flush }
## FIXME: this isn't quite right. 
sub flush($) {$_->[0]->{output}->autoflush = 1 }

# Use this to set where to write to. output can be a 
# file object or a string. This code raises IOError on error.
sub write
{
    my $self = shift;
    $self->{output}->print(@_);
}

# used to write to a debugger that is connected to this
# `str' written will have a newline added to it
#
sub writeline($$)
{
    my ($self, $msg) = @_;
    $self->{output}->write("${msg}\n")
}

unless (caller) {
    my $in = Devel::Trepan::IO::InputBase->new(*main::STDIN);
}

1;
