# -*- coding: utf-8 -*-
# Copyright (C) 2014 Rocky Bernstein <rocky@cpan.org>
# Debugger Input/Output TTY client-side interface.

# FIXME: most of this is common with TTYSever. Just the
# master slave names are reversed.

use warnings; use strict;

use rlib '../../..';

package Devel::Trepan::IO::TTYClient;
use English qw ( -no_match_vars );
use Devel::Trepan::IO::TCPPack;
use Devel::Trepan::Util qw(hash_merge);
use IO::Pty;
our(@ISA);

use constant DEFAULT_INIT_OPTS => {
    open        => 1,
    logger  => undef,  # Complaints should be sent here.
};

sub open($;$);

sub new($;$)
{
    my ($class, $opts) = @_;
    $opts    = hash_merge($opts, DEFAULT_INIT_OPTS);
    my $self = {
        input       => $opts->{input},
        output      => $opts->{output},
        state       => 'uninit',
        logger      => $opts->{logger},
        line_edit   => 0
    };
    bless $self, $class;
    $self->open($opts) if $opts->{open};
    return $self;
}

sub is_interactive($)  {
    my $self = shift;
    return -t $self->{input};
}


sub have_term_readline($)
{
    return 0;
}

# Closes server connection.
# FIXME dry with TTYServer by making a common TTY routine
sub close
{
    my $self = shift;
    $self->{state} = 'closing';
    close($self->{input});
    close($self->{output});
    $self->{state} = 'uninit';
    $self->{input} = $self->{output} = undef;
    print {$self->{logger}} "Disconnected\n" if $self->{logger};
}


sub is_disconnected($)
{
    my $self = shift;
    return 'disconnected' eq $self->{state};
}

sub open($;$)
{
    my ($self, $opts) = @_;
    $opts = hash_merge($self, $opts);

    $self->{input}  = $opts->{input}  || new IO::Pty;
    $self->{output} = $opts->{output} || new IO::Pty;

    # Flush output as soon as possible (autoflush).
    my $oldfh = select($self->{output});
    $OUTPUT_AUTOFLUSH = 1;
    select($oldfh);

    $self->{state} = 'listening';
}

# Read one message unit.
# EOFError will be raised on EOF.
sub read_msg($)
{
    my($self) = @_;
    my $fh = $self->{input};
    # print "+++ client wants input on ", $self->{input}->ttyname(), "\n";
    my $msg;
    unless (eof($fh)) {
	$msg = <$fh>;
	return unpack_msg($msg) if $msg;
    }
    die "Remote client has closed connection";
}

# This method the debugger uses to write. In contrast to
# writeline, no newline is added to the } to `str'. Also
# msg doesn't have to be a string.
# FIXME dry with TTYServer by making a common TTY routine
sub write($$)
{
    my($self, $msg) = @_;
    # print "+++ client will output on", $self->{output}->ttyname(), "\n";
    my $fh = $self->{output};
    print $fh pack_msg($msg) . "\n";
}


# FIXME dry with TTYServer by making a common TTY routine
sub writeline($$)
{
    my($self, $msg) = @_;
    $self->write($msg . "\n");
}

# Demo
unless (caller) {
    my $client = __PACKAGE__-> new({'open' => 1});
    my $client_input_name = $client->{input}->ttyname();
    my $client_output_name = $client->{output}->ttyname();
    print "input tty: $client_input_name, output tty: $client_output_name\n";
    if (scalar @ARGV) {
	require Devel::Trepan::IO::TTYServer;
	my $pid = fork();
	if ($pid) {
	    print "Client pid $$...\n";
	    print "client before read\n";
	    my $msg = $client->read_msg();
	    print "Client read from server message: $msg\n";
	    $client->writeline("client to server");
	    print "client before second read\n";
	    $msg = $client->read_msg();
	    print "Client read from server message: $msg\n";
	    print "Client $$ is done but waiting on server $pid\n";
	    waitpid($pid, 0);
	    $client->close();
	    print "Client is leaving\n";
	} else {
	    print "Server pid $$...\n";
	    require Devel::Trepan::IO::TTYServer;
	     # Server's input goes to client's output and vice versa
	    my $server = Devel::Trepan::IO::TTYServer->new(
		 {'open'=> 1,
		  'input'  => $client->{output}->slave,
		  'output' => $client->{input}->slave,
		 });
	    print "server before write\n";
	    $server->writeline("server to client");
	    print "server before read\n";
	    my $msg = $server->read_msg();
	    print "Server read from client message: $msg\n";
	    print "server before second write\n";
	    $server->write("server to client nocr");
	    sleep(1);
	    print "Server is leaving\n";
	    $server->close();
	}
    } else {
	my $client = __PACKAGE__->new({'open' => 1});
	$client->close();
    }
}

1;
