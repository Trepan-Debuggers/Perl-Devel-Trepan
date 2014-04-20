# -*- coding: utf-8 -*-
# Copyright (C) 2014 Rocky Bernstein <rocky@cpan.org>
# Debugger Server Input/Output FIFO interface.

use warnings; use strict;

use rlib '../../..';

package Devel::Trepan::IO::FIFOServer;

use English qw ( -no_match_vars );
use Fcntl;
use Devel::Trepan::IO::TCPPack;
use Devel::Trepan::Util qw(hash_merge);

# use File::Temp qw(tempdir);
# use File::Spec::Functions qw(catfile);
use POSIX qw(mkfifo);

use constant DEFAULT_INIT_OPTS => {
    open        => 1,
    logger      => undef,  # Complaints should be sent here.

    # input and output names are the reverse of the client
    input_name  => '/tmp/trepanpl.inputfifo',
    input_mode  => 0777,
    input       => undef,
    output_name => '/tmp/trepanpl.outputfifo',
    output_mode => 0777,
    output      => undef,

    reuse       => 1,

    # name_pat pattern to go into tmmname
};

sub new($;$)
{
    my ($class, $opts) = @_;
    $opts = hash_merge($opts, DEFAULT_INIT_OPTS);
    my $self = {
        input       => undef,
	input_name  => $opts->{input_name},
	input_mode  => $opts->{input_mode},
        output      => undef,
	output_name => $opts->{output_name},
	output_mode => $opts->{output_mode},
        state       => 'uninit',
        logger      => $opts->{logger},
        line_edit   => 0
    };
    bless $self, $class;
    $self->open($opts) if $opts->{open};
    return $self;
}

sub is_connected($)
{
    my $self = shift;
    $self->{state} = 'connected' if
        $self->{input} and $self->{output};
    return $self->{state} eq 'connected';
}

sub is_interactive($)  {
    0;
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
        close($FIFO) if $FIFO;
    }
    $self->{state} = 'uninit';
    $self->{input} = $self->{output} = undef;
    print {$self->{logger}} "Disconnected FIFO server\n" if $self->{logger};
}

sub open($;$)
{
    my ($self, $opts) = @_;
    $opts = hash_merge($self, $opts);

    foreach my $tuple ( [$opts->{input_name},  $opts->{input_mode}],
			[$opts->{output_name}, $opts->{output_mode}] ) {
	my ($named_pipe, $create_mode) = @$tuple;
	if ( -p $named_pipe ) {
	    die "FIFO $named_pipe already exists" unless $opts->{reuse};
	} else {
	    POSIX::mkfifo($named_pipe, $create_mode)
		or die "mkfifo($named_pipe) failed: $!";
	}
    }
    sysopen($self->{output}, $self->{output_name}, O_RDWR) or
	die "Can't open $self->{output_name} for writing; $!";

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
    my $fh = $self->{input};
    unless ($fh) {
	print {$self->{logger}} "read on disconnected input\n" if $self->{logger};
	return '';
    }
    # print "+++ server self input ($self->{input_name}) ", $fh, "\n";
    my $msg;
    unless (eof($fh)) {
	$msg = <$fh>;
    }
    if ($msg ne '-1') {
	return unpack_msg($msg);
    } else {
	print {$self->{logger}} "Client disconnected\n" if $self->{logger};
	return unpack_msg('');
	die "Remote has closed connection";
    }
}

# This method the debugger uses to write. In contrast to
# writeline, no newline is added to the } to `str'. Also
# msg doesn't have to be a string.
# FIXME dry with FIFOClient by making a common FIFO routine
sub write($$)
{
    my($self, $msg) = @_;
    # print "+++ server self output ($self->{output_name})\n";
    syswrite($self->{output}, pack_msg($msg) . "\n");
}

# FIXME dry with FIFOClient by making a common FIFO routine
sub writeline($$)
{
    my($self, $msg) = @_;
    $self->write($msg . "\n");
}

# Demo
unless (caller) {
    my $server = __PACKAGE__->new({open => 1, logger=>*STDOUT});
    if (scalar @ARGV) {
      require Devel::Trepan::IO::FIFOClient;
      my $pid = fork();
      if (scalar @ARGV) {
         my $pid = fork();
         if ($pid) {
             print "Server pid $$...\n";
             my $client = __PACKAGE__->new({'open' => 1});
	     print "server before write\n";
             $server->writeline("server to client");
	     print "server before read\n";
             my $msg = $server->read_msg();
	     print "Server read from client message: $msg\n";
	     print "server before second write\n";
             $server->write("server to client nocr");
	     print "Server $$ is done but waiting on client $pid\n";
	     waitpid($pid, 0);
	     $server->close();
	     print "Server is leaving\n";
         } else {
             print "Client pid $$...\n";
             my $client = Devel::Trepan::IO::FIFOClient->new({'open'=> 1});
	     print "client before read\n";
             my $msg = $client->read_msg();
	     print "Client read from server message: $msg\n";
             $client->writeline("client to server");
	     print "client before second read\n";
             $msg = $client->read_msg();
	     print "Client read from server message: $msg\n";
	     print "Client is leaving\n";
	     $client->close();
         }
     } else {
	 my $client = __PACKAGE__->new({'open' => 1});
	 $client->close();
     }
  }
}

1;
