# -*- coding: utf-8 -*-
# Copyright (C) 2011 Rocky Bernstein <rocky@cpan.org>
# Interface for client (i.e. user to communication-device) interaction.
# The debugged program is at the other end of the communcation.

use warnings; no warnings 'redefine'; 
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
use strict; 

@ISA = qw(Devel::Trepan::Interface Exporter);


use constant DEFAULT_INIT_CONNECTION_OPTS => {
    open => 1,
    io   => 'tcp'
};

sub new 
{
    my($class, $inp, $out, $inout, $user_opts, $connection_opts) = @_;
    $connection_opts = hash_merge($connection_opts, DEFAULT_INIT_CONNECTION_OPTS);

    unless (defined($inout)) {
        my $server_type = $connection_opts->{'io'};
        # FIXME: complete this.
        # if 'FIFO' == self.server_type
        #   Mfifoclient.FIFOClient(opts=@connection_opts)
        # elsif :tcp == self.server_type
        $inout = Devel::Trepan::IO::TCPClient->new($connection_opts);
        # }
    }
    my $self = {
    	output => $out,
    	inout  => $inout,
    	input  => $inp,
    	user   => Devel::Trepan::Interface::User->new($inp, $out, $user_opts)
    };
    bless $self, $class;
    return $self;
    
}

sub is_closed($) 
{
    my ($self) = @_;
    $self->{inout}->is_closed
}

# Called when a dangerous action is about to be done to make sure
# it's okay. `prompt' is printed; user response is returned.
# FIXME: make common routine for this and user.rb
sub confirm($;$$)
{
    my ($self, $prompt, $default) = @_;
    $self->{user}->confirm($prompt, $default);
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
	$coded_line = $self->{inout}->read_msg;
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
    $self->{inout}->writeline($code . $msg);
}
  
# Demo
unless (caller) {
    my $intf = Devel::Trepan::Interface::Client->new(undef, undef, undef, undef, 
						     {open => 0});
}

1;
