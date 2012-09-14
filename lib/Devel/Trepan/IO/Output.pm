# Copyright (C) 2011-2012 Rocky Bernstein <rocky@cpan.org>
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

use rlib '../../..';
use IO::Handle;

# This is an abstract class that specifies debugger output.
package Devel::Trepan::IO::Output;
# use Devel::Trepan::Util qw(hash_merge);

use vars qw(@EXPORT @EXPORT_OK);

sub new($;$$) {
    my($class, $output, $opts) = @_;
    $opts ||= {};
    unless ($output) {
        open STDOUT_DUP, ">&", STDOUT;
        $output = *STDOUT_DUP;
    };
    my $self = {
        flush_after_write => 0,
        output            => $output,
        eof               => 0
    };
    bless $self, $class;
    return $self;
}

sub is_closed($) {
    my($self) = @_;
    ! $self->{output} || $self->is_eof;
}
sub close($) {
    my($self) = @_;
    close $self->{output} unless $self->is_closed;
    $self->{eof} = 1;
}

sub is_eof($) {
    my($self) = @_;
    return $self->{eof};
}

sub flush($) {
    my($self) = @_;
    $self->{output}->autoflush(1);
}

# Use this to set where to write to. output can be a 
# file object or a string. This code raises IOError on error.
sub write($$) {
    my ($self, $msg) = @_;
    print {$self->{output}} $msg;
}

# used to write to a debugger that is connected to this
# `str' written will have a newline added to it
#
sub writeline($$) {
    my ($self, $msg) = @_;
    print {$self->{output}} $msg . "\n" unless $self->is_closed();
}

if (__FILE__ eq $0) {
    my $out = Devel::Trepan::IO::Output->new();
    CORE::close(STDOUT);
    $out->writeline("Now is the time!");
}

1;
