# -*- coding: utf-8 -*-
# Copyright (C) 2012 Rocky Bernstein <rocky@cpan.org>

use warnings; no warnings 'redefine'; 
use rlib '../../..';

# Interface for debugging a program but having user control
# reside outside of the debugged process, possibly on another
# computer
package Devel::Trepan::Interface::Bullwinkle;
use English qw( -no_match_vars );
our (@ISA);

# Our local modules
use if !@ISA, Devel::Trepan::Interface;
use if !@ISA, Devel::Trepan::IO::Input;
use Devel::Trepan::Util qw(hash_merge);
# use if !@ISA, Devel::Trepan::IO::TCPServer;
use strict; 

@ISA = qw(Devel::Trepan::Interface Exporter);

use constant DEFAULT_INIT_CONNECTION_OPTS => {
    io => 'TCP',
    logger => undef  # An Interface. Complaints go here.
};

sub new
{
    my($class, $inp, $out, $connection_opts) = @_;
    $connection_opts = hash_merge($connection_opts, DEFAULT_INIT_CONNECTION_OPTS);

    # at_exit { finalize };
    ## FIXME:
    my $self = {
        output => $inp || *STDOUT,
        input  => $out || *STDIN,
        interactive => 0, 
        logger => $connection_opts->{logger}
    };
    bless $self, $class;
    return $self;
}
  
# # Closes both input and output
# sub close($)
# {
#     my ($self) = @_;
#     if ($self->{inout} && $self->{inout}->is_connected) {
#         $self->{inout}->write(QUIT . 'bye');
#         $self->{inout}->close;
#     }
# }
  
sub is_closed($) 
{
    my($self)  = shift;
    # FIXME: 
    # $self->{input}->is_eof && $self->{output}->is_eof;
    0
}

sub is_interactive($) { 0 }

sub has_completion($) { 0 }

# Called when a dangerous action is about to be done to make sure
# it's okay. `prompt' is printed; user response is returned.
# FIXME: make common routine for this and user.rb
sub confirm($;$$)
{
    my ($self, $prompt, $default) = @_;
    $default = 1 unless defined($default);
    return $default;
}
  
sub is_input_eof($)
{
    my ($self) = @_;
    0;
}

# used to write to a debugger that is connected to this
# server; 

### FIXME: 
use Data::Dumper; 
sub msg($;$)
{
    my ($self, $msg) = @_;
    ### FIXME
    print Data::Dumper::Dumper($msg), "\n";
    # $self->{inout}->writeline(PRINT . $msg);
}

# used to write to a debugger that is connected to this
# server; `str' written will have a newline added to it
sub errmsg($;$)
{
    my ($self, $msg) = @_;
    ### FIXME
    print Data::Dumper::Dumper($msg), "\n";
    # $self->{inout}->writeline(SERVERERR . $msg);
}

# used to write to a debugger that is connected to this
# server; `str' written will not have a newline added to it
sub msg_nocr($$)
{    
    my ($self, $msg) = @_;
    ### FIXME
    print "$msg";
    # $self->{inout}->write(PRINT .  $msg);
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

# Demo
unless (caller) {
    my $intf = Devel::Trepan::Interface::Bullwinkle->new();
    $intf->msg('Testing 1, 2, 3..')
}

1;
