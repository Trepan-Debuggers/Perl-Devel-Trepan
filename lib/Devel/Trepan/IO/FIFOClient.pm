# -*- coding: utf-8 -*-
# Copyright (C) 2014 Rocky Bernstein <rocky@cpan.org>
# Debugger Input/Output FIFO client interface.

use warnings; use strict;

use rlib '../../..';

package Devel::Trepan::IO::FIFOClient;
use English qw ( -no_match_vars );
use POSIX qw(mkfifo);
use Fcntl;

use Devel::Trepan::IO::TCPPack;
use Devel::Trepan::Util qw(hash_merge);
our(@ISA);

use constant DEFAULT_INIT_OPTS => {
    open        => 1,

    # input and output names are the reverse of the server
    input_name  => '/tmp/trepanpl.outputfifo',
    input       => undef,
    input_mode  => 0777,
    output_name => '/tmp/trepanpl.inputfifo',
    output      => undef,
    output_mode => 0777,
    logger  => undef,  # Complaints should be sent here.
    # name_pat pattern to go into tmpname
};

#   attr_reader :state

sub open($;$);

sub new($;$)
{
    my ($class, $opts) = @_;
    $opts    = hash_merge($opts, DEFAULT_INIT_OPTS);
    my $self = {
        addr => undef,
        buf  => '',
        line_edit => 0, # Our name for GNU readline capability
	input_name  => $opts->{input_name},
	input_mode  => $opts->{input_mode},
        output      => undef,
	output_name => $opts->{output_name},
	output_mode => $opts->{output_mode},
        state       => 'uninit',
        logger      => $opts->{logger}
    };
    bless $self, $class;
    $self->open($opts) if $opts->{open};
    return $self;
}

sub is_interactive($)  {
    0
}

sub have_term_readline($)
{
    return 0;
}

# Closes server connection.
# FIXME dry with FIFOClient by making a common FIFO routine
sub close
{
    my $self = shift;
    $self->{state} = 'closing';
    foreach my $FIFO ( $self->{input}, $self->{output} ) {
        close($FIFO);
    }
    $self->{state} = 'uninit';
    $self->{input} = $self->{output} = undef;
    print {$self->{logger}} "Disconnected FIFO client\n" if $self->{logger};
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

    foreach my $tuple ( [$opts->{input_name},  $opts->{input_mode}],
			[$opts->{output_name}, $opts->{output_mode} ] ) {
	my ($named_pipe, $create_mode) = @$tuple;
	unless ( -p $named_pipe ) {
	    mkfifo($named_pipe, $create_mode)
		or die "mkfifo($named_pipe) failed: $!";

	}

    }
    sysopen($self->{output}, $self->{output_name}, O_NONBLOCK|O_RDWR) or
	die "Can't open $self->{output_name} for writing: $!";

    # Flush output as soon as possbile (autoflush).
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
    unless ($self->{input}) {
	sysopen($self->{input}, $self->{input_name}, O_RDONLY) or
	    die "Can't open $self->{input_name} for reading";
    }
    my $fh = $self->{input};
    # print "+++ client self input ($self->{input_name}) ", $fh, "\n";
    my $msg;
    unless (eof($fh)) {
	$msg = <$fh>;
	return unpack_msg($msg) if $msg;
    }
    die "Remote has closed connection" if eof($fh);
}

# This method the debugger uses to write. In contrast to
# writeline, no newline is added to the end of to `str'. Also
# $msg doesn't have to be a string.
# FIXME dry with FIFOServer by making a common FIFO routine
sub write($$)
{
    my($self, $msg) = @_;
    # print "+++ client self output ($self->{output_name})\n";
    syswrite($self->{output}, pack_msg($msg) . "\n");
}


# FIXME dry with FIFOServer by making a common FIFO routine
sub writeline($$)
{
    my ($self, $msg) = @_;
    $self->write($msg . "\n");
}

# Demo
unless (caller) {
     if (scalar @ARGV) {
	 require Devel::Trepan::IO::FIFOServer;
         my $pid = fork();
         if ($pid) {
             print "Client pid $$...\n";
             my $client = __PACKAGE__-> new({'open' => 1});
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
	     require Devel::Trepan::IO::FIFOServer;
             my $server = Devel::Trepan::IO::FIFOServer->new();
	     print "server before write\n";
             $server->writeline("server to client");
	     print "server before read\n";
             my $msg = $server->read_msg();
	     print "Server read from client message: $msg\n";
	     print "server before second write\n";
             $server->write("server to client nocr");
	     print "Server is leaving\n";
	     $server->close();
         }
     } else {
	 my $client = __PACKAGE__->new({'open' => 1});
	 $client->close();
     }
}

1;
