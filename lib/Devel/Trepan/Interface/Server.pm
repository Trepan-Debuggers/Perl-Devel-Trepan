# -*- coding: utf-8 -*-
# Copyright (C) 2011-2014 Rocky Bernstein <rocky@cpan.org>

use warnings; no warnings 'redefine';

# Interface for debugging a program but having user control
# reside outside of the debugged process, possibly on another
# computer
package Devel::Trepan::Interface::Server;
use English qw( -no_match_vars );
our (@ISA);

# Our local modules
BEGIN {
    my @OLD_INC = @INC;
    use rlib '../../..';
    use if !@ISA, Devel::Trepan::Interface;
    use if !@ISA, Devel::Trepan::Interface::ComCodes;
    use if !@ISA, Devel::Trepan::IO::Input;
    use Devel::Trepan::Util qw(hash_merge YES NO);
    use if !@ISA, Devel::Trepan::IO::TCPServer;
    use if !@ISA, Devel::Trepan::IO::TTYServer;
    @INC = @OLD_INC;
}

use strict;

@ISA = qw(Devel::Trepan::Interface Exporter);

use constant DEFAULT_INIT_CONNECTION_OPTS => {
    io => 'TCP',
    logger => undef  # An Interface. Complaints go here.
};

sub new
{
    my($class, $input, $out, $connection_opts) = @_;
    $connection_opts = hash_merge($connection_opts,
				  DEFAULT_INIT_CONNECTION_OPTS);

    # at_exit { finalize };
    my $server_type = $connection_opts->{io};
    my $self = {
        interactive => 1, # Or at least so we think initially
        logger => $connection_opts->{logger}
    };
    unless (defined($input)) {
	my $server;
	if ('tty' eq $server_type) {
	    $server = Devel::Trepan::IO::TTYServer->new($connection_opts);
	} else {
	    $server = Devel::Trepan::IO::TCPServer->new($connection_opts);
	}
	# For Compatability
	$self->{output} = $self->{input} = $self->{inout} = $server;
    }

    bless $self, $class;
    return $self;
}

  # Closes both input and output
sub close($)
{
    my ($self) = @_;
    if ($self->{output} && $self->{output}->can('is_connected')) {
        $self->{output}->write(QUIT . 'bye');
        $self->{output}->close;
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
    my @msg = split(/\n/, $msg);
    foreach my $line (@msg) {
	$self->{inout}->writeline(PRINT . $line);
    }
}

# used to write to a debugger that is connected to this
# server; `str' written will have a newline added to it
sub errmsg($;$)
{
    my ($self, $msg) = @_;
    my @msg = split(/\n/, $msg);
    foreach my $line (@msg) {
	$self->{inout}->writeline(SERVERERR . $line);
    }
}

# used to write to a debugger that is connected to this
# server; `str' written will not have a newline added to it
sub msg_nocr($$)
{
    my ($self, $msg) = @_;
    $self->{inout}->write(PRINT .  $msg);
}

# read a debugger command
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
	if ($coded_line)  {
	    my $read_ctrl = substr($coded_line,0,1);
	    return substr($coded_line, 1);
	} else {
	    return "";
	}
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
    my $intf = __PACKAGE__->new(undef, undef, {open => 0, io => 'TCP'});
    # $intf->close();
    $intf = __PACKAGE__->new(undef, undef,
			     {open => 1, io => 'tty', logger=>\*STDOUT});
    $intf->close();
}

1;
