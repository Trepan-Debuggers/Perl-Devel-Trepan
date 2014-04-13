# -*- coding: utf-8 -*-
# Copyright (C) 2014 Rocky Bernstein <rocky@cpan.org>
# Debugger Input/Output TTY server-side interface.


# FIXME: most of this is common with TTYClient. Just the
# master slave names are reversed.

use warnings; use strict;

use rlib '../../..';

package Devel::Trepan::IO::TTYServer;

use English qw ( -no_match_vars );
use Devel::Trepan::IO::TCPPack;
use Devel::Trepan::Util qw(hash_merge);
use IO::Pty;

use constant DEFAULT_INIT_OPTS => {
    open        => 1,
    logger      => undef,  # Complaints should be sent here.
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

sub is_connected($)
{
    my $self = shift;
    $self->{state} = 'connected' if
        $self->{input} and $self->{output};
    return $self->{state} eq 'connected';
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
# FIXME dry with TTYClient by making a common TTY routine
sub close
{
    my $self = shift;
    $self->{state} = 'closing';
    close($self->{input});
    if ($self->{output}) {
	close($self->{output});
    }
    $self->{state} = 'uninit';
    $self->{input} = $self->{output} = undef;
    print {$self->{logger}} "Disconnected tty server\n" if $self->{logger};
}

sub open($;$)
{
    my ($self, $opts) = @_;
    $opts = hash_merge($self, $opts);

    $self->{input}  = $opts->{input}  || new IO::Pty;
    $self->{output} = $opts->{output} || new IO::Pty;

    if ($self->{logger}) {
	my $msg = sprintf("output slave %s; input slave %s",
			  $self->{output}->ttyname(), $self->{input}->ttyname());
	print {$self->{logger}} "$msg\n";
    }

    $self->{input}->slave->set_raw() if $self->{input}->isa('IO::Pty');

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
    unless ($fh) {
	print {$self->{logger}} "read on disconnected input\n" if $self->{logger};
	return '';
    }
    # print "+++ server will get input from ", $self->{input}->ttyname(), "\n";
    # FIXME: look over some more
    my $msg;
    until ($msg) {
	$msg = <$fh>;
	chomp $msg;
    };
    if ($msg ne '-1') {
	return unpack_msg($msg);
    } else {
	print {$self->{logger}} "Client disconnected\n" if $self->{logger};
	return unpack_msg('');
    }
}

# This method the debugger uses to write. In contrast to
# writeline, no newline is added to the } to `str'. Also
# msg doesn't have to be a string.
# FIXME dry with TTYClient by making a common TTY routine
sub write($$)
{
    my($self, $msg) = @_;
   #  print '+++ XXX server write: ', pack_msg($msg);
    print {$self->{output}} pack_msg($msg) . "\n";
}

# FIXME dry with TTYClient by making a common TTY routine
sub writeline($$)
{
    my($self, $msg) = @_;
    $self->write($msg . "\n");
}

# Demo
unless (caller) {
  my $server = __PACKAGE__->new({open => 1, logger=>*STDOUT});
  if (scalar @ARGV) {
      require Devel::Trepan::IO::TTYClient;
      my $pid = fork();
      if (scalar @ARGV) {
         my $pid = fork();
         if ($pid) {
             print "Server pid $$...\n";
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
	     # Client's input goes to server's output and vice versa
             my $client = Devel::Trepan::IO::TTYClient->new(
		 {'open'=> 1,
		  'input'  => $server->{output}->slave,
		  'output' => $server->{input}->slave,
		 });
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
