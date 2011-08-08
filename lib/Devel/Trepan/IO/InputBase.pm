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

use lib '../../..';

package Devel::Trepan::IO::InputBase;

use Devel::Trepan::Util qw(hash_merge);
use vars qw(@EXPORT @EXPORT_OK);

@EXPORT = qw(DEFAULT_OPTS);

use constant DEFAULT_OPTS => {
    line_edit => 0,
};

sub new($$;$) {
    my($class, $input, $opts)  = @_;
    $opts ||= {};
    hash_merge($opts, DEFAULT_OPTS);
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
    close $self->{input} unless $self->is_closed;
    $self->{eof} = 1;
}

sub have_gnu_readline() {
    0;
}

sub is_eof($) {
    my($self) = shift;
    return $self->{eof};
}

sub is_interactive() {
    0;
}

if (__FILE__ eq $0) {
    my $in = Devel::Trepan::IO::InputBase->new(*main::STDIN);
    if (scalar(@ARGV) > 0) {
	print "Enter some text: ";
	my $line = $in->readline;
	print "You entered ${line}";
    }
}

1;
