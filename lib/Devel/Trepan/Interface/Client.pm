# -*- coding: utf-8 -*-
# Copyright (C) 2011-2012, 2014 Rocky Bernstein <rocky@cpan.org>
# Interface for client (i.e. user to communication-device) interaction.
# The debugged program is at the other end of the communcation.

use warnings; use utf8; no warnings 'redefine';
use rlib '../../..';

# Interface for a user which is attached to a debugged process via
# some sort of communication medium (e.g. socket, tty, FIFOs).  This
# could be on the same computer in a different process or on a remote
# computer.
package Devel::Trepan::Interface::Client;
our (@ISA);
use if !@ISA, Devel::Trepan::Interface;
use if !@ISA, Devel::Trepan::Interface::ComCodes;
use if !@ISA, Devel::Trepan::Interface::User;
use if !@ISA, Devel::Trepan::IO::Input;
use Devel::Trepan::Util qw(hash_merge);
use if !@ISA, Devel::Trepan::IO::TCPClient;
use if !@ISA, Devel::Trepan::IO::FIFOClient;
use strict;

use constant HAVE_TTY => eval q(use Devel::Trepan::IO::TTYClient; 1) ? 1 : 0;

@ISA = qw(Devel::Trepan::Interface Exporter);


use constant DEFAULT_INIT_CONNECTION_OPTS => {
    open => 1,
    client => ['tcp']
};

sub new
{
    my($class, $inp, $out, $user_opts, $connection_opts) = @_;
    $connection_opts = hash_merge($connection_opts,
				  DEFAULT_INIT_CONNECTION_OPTS);
    my $client;
    unless (defined($inp)) {
        my $client_opts = $connection_opts->{'client'};
        if ('tty' eq $client_opts->[0] and HAVE_TTY) {
	    my $tty_opts = {
		inpty_name  => $client_opts->[1],
		outpty_name => $client_opts->[2],
	    };
	    $client = Devel::Trepan::IO::TTYClient->new($tty_opts);
        } elsif ('tcp' eq $client_opts->[0]) {
	    $client = Devel::Trepan::IO::TCPClient->new($connection_opts);
        } elsif ('fifo' eq $client_opts->[0]) {
	    $client = Devel::Trepan::IO::FIFOClient->new($connection_opts);
	} else {
	    die "Unknown communication protocol: $client_opts->[0]";
        }
    }
    my $self = {
        output => $client,
	input  => $client,
        user   => Devel::Trepan::Interface::User->new($inp, $out, $user_opts)
    };
    bless $self, $class;
    return $self;

}

sub is_closed($)
{
    my ($self) = @_;
    $self->{input}->is_closed
}

# Called when a dangerous action is about to be done to make sure
# it's okay. `prompt' is printed; user response is returned.
# FIXME: make common routine for this and user.rb
sub confirm($;$$)
{
    my ($self, $prompt, $default) = @_;
    $self->{user}->confirm($prompt, $default);
}

sub has_completion($)
{
    my ($self) = @_;
    $self->{user}->has_completion;
}

sub set_completion($$$)
{
    my ($self, $completion_fn, $list_completion_fn) = @_;
    $self->{user}->set_completion($completion_fn, $list_completion_fn);
}

sub read_command($$)
{
    my ($self, $prompt) = @_;
    $self->{user}->read_command($prompt);
}

# Send a message back to the server (in contrast to the local user
# output channel).
sub read_remote
{
    my ($self) = @_;
    my $coded_line = undef;
    until ($coded_line) {
        $coded_line = $self->{input}->read_msg;
    }
    my $control = substr($coded_line, 0, 1);
    my $remote_line = substr($coded_line, 1);
    return ($control, $remote_line);
}

# Send a message back to the server (in contrast to the local user
# output channel).
sub write_remote($$$)
{
    my ($self, $code, $msg) = @_;
    # FIXME change into write_xxx
    $self->{output}->writeline($code . $msg);
}

# Demo
unless (caller) {
    print "HAVE_TTY: ", HAVE_TTY, "\n";
    my $intf = Devel::Trepan::Interface::Client->new(undef, undef, undef, undef,
                                                     {open => 0});
}

1;
