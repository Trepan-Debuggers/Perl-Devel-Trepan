# -*- coding: utf-8 -*-
# Copyright (C) 2011 Rocky Bernstein <rocky@cpan.org>

# A base class for a debugger interface.

use strict;
use Exporter;
use warnings;
use Carp ();

package Devel::Trepan::Interface;
use rlib '../..';
use vars qw(@EXPORT @ISA @YN);
@ISA = qw(Exporter);
@EXPORT = qw(YES NO YES_OR_NO @YN readline close new);

use Devel::Trepan::IO::Input;
use Devel::Trepan::IO::Output;

# A debugger interface handles the communication or interaction with between
# the program and the outside portion which could be
#  - a user, 
#  - a front-end that talks to a user, or
#  - another interface in another process or computer

# attr_accessor :history_save, :interactive, :input, :output

use constant YES => qw(y yes oui si yep ja);
@YN = YES;
use constant NO => qw(n no non nope nein);
push(@YN, NO);

sub new($;$$$) {
    my($class, $inp, $out, $opts)  = @_;
    $opts ||= {};
    my $input_opts = {
	readline => $opts->{readline}
    };

    my $self = {
	histfile      => undef,
	history_save  => 0,
	histsize      => undef,
	line_edit     => $opts->{line_edit},
	input         => $inp || Devel::Trepan::IO::Input->new(undef, $input_opts),
	opts          => $opts,
	output        => $out || Devel::Trepan::IO::Output->new
    };
    bless $self, $class;
    $self;
}

sub add_history($$) {}

# Closes all input and/or output.
sub close($) {
    my($self) = shift;
    eval {
	$self->{input}->close if
	    defined($self->{input}) && !$self->{input}->is_closed;
	$self->{output}->close if
	    defined($self->{output}) && !$self->{output}->is_closed;
    };
}

# Called when a dangerous action is about to be done to make sure
# it's okay. `prompt' is printed; user response is returned.
sub confirm($;$) {
    my($self, $prompt, $default) = @_;
    Carp::croak "RuntimeError, Trepan::NotImplementedMessage";
}

# Common routine for reporting debugger error messages.
sub errmsg($;$$) {
    my($self, $str, $prefix) = @_;
    $prefix = '** ' unless defined $prefix;
    if (ref($str) eq 'ARRAY') {
    	foreach my $s (@$str) {
    	    $self->errmsg($s);
    	}
    } else {
        foreach my $s (split /\n/, $str) {
	    $self->msg(sprintf("%s%s" , $prefix, $s));
        }
    }
}

sub is_input_eof($) {
    my $self = shift;
    return 1 unless defined $self->{input};
    my $input = $self->{input};
    $input->can("is_eof") ? $input->is_eof : $input->eof;
}

#     # Return true if interface is interactive.
#     def interactive?
#       # Default false and making subclasses figure out how to determine
#       # interactiveness.
#       false 
#     end

# used to write to a debugger that is connected to this
# server; `str' written will have a newline added to it.
sub msg($$) {
    my($self, $str) = @_;
    # if (str.is_a?(Array)) {
    # 	foreach my $s (@$str) {
    # 	    errmsg($s);
    # 	}
    # } else {
        $self->{output}->writeline($str);
    # }
}

# used to write to a debugger that is connected to this
# server; `str' written will not have a newline added to it
sub msg_nocr($$) {
    my($self, $msg) = @_;
    $self->{output}->write($msg);
}

sub read_command($;$) {
    my($self, $prompt) = @_;
    my $line = readline($prompt);
    # FIXME: Do something with history?
    return $line;
}

sub read_history($$) {}

sub readline($;$) {
    my($self, $prompt) = @_;
    ## FIXME
    ## $self->{output}->flush;
    $self->{output}->write($prompt) if $prompt;
    $self->{input}->readline();
}

sub save_history($$) {}

#sub DESTROY {
#    my $self = shift;
#    if ($self->{output} && defined($self->{output}) && ! $self->{output}->is_closed) {
#	eval {
#	    $self->msg(sprintf("%sThat's all, folks...",
#			       (defined($Devel::Trepan::PROGRAM) ? 
#				"${Devel::Trepan::PROGRAM}: " : '')));
#	};
#    }
#    $self->close;
#}

# Demo
if (__FILE__ eq $0) {
    print join(', ', YES), "\n";
    print join(', ', NO), "\n";
    print join(', ', @YN), "\n";
    my $interface = Devel::Trepan::Interface->new;
}

1;
