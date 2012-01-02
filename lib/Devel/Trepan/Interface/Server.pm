# -*- coding: utf-8 -*-
# Copyright (C) 2011 Rocky Bernstein <rocky@cpan.org>

use warnings; no warnings 'redefine'; 
use rlib '../../..';

# Interface for debugging a program but having user control
# reside outside of the debugged process, possibly on another
# computer
package Devel::Trepan::Interface::Server;
use English qw( -no_match_vars );
our (@ISA);

# Our local modules
use if !defined(@ISA), Devel::Trepan::Interface;
use if !defined(@ISA), Devel::Trepan::Interface::ComCodes;
use if !defined(@ISA), Devel::Trepan::IO::Input;
use Devel::Trepan::Util qw(hash_merge YES NO);
use if !defined(@ISA), Devel::Trepan::IO::TCPServer;
use strict; 

@ISA = qw(Devel::Trepan::Interface Exporter);

use constant DEFAULT_INIT_CONNECTION_OPTS => {
    io => 'TCP',
    logger => undef  # An Inteface. Complaints go here.
};

sub new
{
    my($class, $inout, $out, $connection_opts) = @_;
    $connection_opts = hash_merge($connection_opts, DEFAULT_INIT_CONNECTION_OPTS);

    # at_exit { finalize };
    unless (defined($inout)) {
        my $server_type = $connection_opts->{io};
        # FIXME: complete this.
        # if 'FIFO' == server_type
        #     FIFOServer.new
        # else
        $inout = Devel::Trepan::IO::TCPServer->new($connection_opts);
        # }
    }
    my $self = {
	# For Compatability 
    	output => $inout,
    	inout  => $inout,
    	input  => $inout,
    	interactive => 1, # Or at least so we think initially

	logger => $connection_opts->{logger}
    };
    bless $self, $class;
    return $self;
}
  
  # Closes both input and output
sub close($)
{
    my ($self) = @_;
    if ($self->{inout} && $self->{inout}->is_connected) {
	$self->{inout}->write(QUIT . 'bye');
	$self->{inout}->close;
    }
}
  
sub is_closed($) 
{
    my ($self) = @_;
    $self->{inout}->is_closed
}

sub is_interactive($)
{
    my $self = shift;
    $self->{input}->is_interactive;
}

sub has_completion($)
{
    0
}

# Called when a dangerous action is about to be done to make sure
# it's okay. `prompt' is printed; user response is returned.
# FIXME: make common routine for this and user.rb
sub confirm($;$$)
{
    my ($self, $prompt, $default) = @_;

    my $reply;
    while (1) {
	# begin
        $self->write_confirm($prompt, $default);
	$reply = $self->readline;
	chomp($reply);
	if (defined($reply)) {
	    ($reply = lc(unpack("A*", $reply))) =~ s/^\s+//;
	} else {
	    return $default;
	}
	if (grep(/^${reply}$/, YES)) {
	    return 1;
	} elsif (grep(/^${reply}$/, NO)) {
	    return 0;
	} else {
	    $self->msg("Please answer 'yes' or 'no'. Try again.");
	}
    }
    return $default;
}
  
# Return 1 if we are connected
sub is_connected($)
{
    my ($self) = @_;
    'connected' eq $self->{inout}->{state};
}
    
# print exit annotation
sub finalize($;$)
{
    my ($self, $last_wishes) = @_;
    $last_wishes = 'QUIT' unless defined $last_wishes;
    $self->{inout}->writeline($last_wishes) if $self->is_connected;
    $self->close;
}
  
sub is_input_eof($)
{
    my ($self) = @_;
    0;
}

# used to write to a debugger that is connected to this
# server; `str' written will have a newline added to it
sub msg($;$)
{
    my ($self, $msg) = @_;
    $self->{inout}->writeline(PRINT . $msg);
}

# used to write to a debugger that is connected to this
# server; `str' written will have a newline added to it
sub errmsg($;$)
{
    my ($self, $msg) = @_;
    $self->{inout}->writeline(SERVERERR . $msg);
}

# used to write to a debugger that is connected to this
# server; `str' written will not have a newline added to it
sub msg_nocr($$)
{    
    my ($self, $msg) = @_;
    $self->{inout}->write(PRINT .  $msg);
}
  
sub read_command($$)
{
    my ($self, $prompt) = @_;
    $self->readline($prompt);
}
  
sub read_data($)
{
    my ($self, $prompt) = @_;
    $self->{inout}->read_data;
}
  
sub readline($;$)
{
    my ($self, $prompt, $add_to_history) = @_;
    # my ($self, $prompt, $add_to_history) = @_;
    # $add_to_history = 1;
    if ($prompt) {
	$self->write_prompt($prompt);
    }
    my $coded_line;
    eval {
	$coded_line = $self->{inout}->read_msg();
    };
    if ($EVAL_ERROR) {
	print {$self->{logger}} "$EVAL_ERROR\n" if $self->{logger};
	$self->errmsg("Server communication protocol error, resyncing...");
	return ('#');
    } else {
	my $read_ctrl = substr($coded_line,0,1);
	substr($coded_line, 1);
    }
}

sub remove_history($;$)
{
    my ($self, $which) = @_;
    return unless ($self->{input}{readline});
    $which = $self->{input}{readline}->where_history() unless defined $which;
    $self->{input}{readline}->remove_history($which);
}

# Return connected
sub state($)
{
    my ($self) = @_;
    $self->{inout}->{state};
}
  
sub write_prompt($$)
{
    my ($self, $prompt) = @_;
    $self->{inout}->write(PROMPT . $prompt);
}
  
sub write_confirm($$$)
{
    my ($self, $prompt, $default) = @_;
    my $code = $default ? CONFIRM_TRUE : CONFIRM_FALSE;
    $self->{inout}->write($code . $prompt)
}
    
# Demo
unless (caller) {
    my $intf = Devel::Trepan::Interface::Server->new(undef, undef, {open => 0});
}

1;
