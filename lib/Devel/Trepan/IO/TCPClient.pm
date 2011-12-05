# -*- coding: utf-8 -*-
# Copyright (C) 2011 Rocky Bernstein <rocky@cpan.org>
# Debugger Socket Input/Output Interface.

use warnings; use strict;

use rlib '../../..';

# Debugger Client Input/Output Socket.
package Devel::Trepan::IO::TCPClient;
use English qw ( -no_match_vars );
use IO::Socket qw(SOCK_STREAM);

use Devel::Trepan::IO::TCPPack;
use Devel::Trepan::Util qw(hash_merge);
our(@ISA);

use constant CLIENT_SOCKET_OPTS => {
      host    => 'localhost', # Symbolic name
      port    => 1027,  # Arbitrary non-privileged port
      open    => 1,
};

#   attr_reader :state

sub open($;$);

sub new($;$)
{
    my ($class, $opts) = @_;
    $opts    = hash_merge($opts, CLIENT_SOCKET_OPTS);
    my $self = {
	addr => undef,
	buf  => '',
	line_edit => 0, # Our name for GNU readline capability
	state     => 'disconnected',
	inout     => undef,
	logger    => undef  # Complaints should be sent here.
    };
    bless $self, $class;
    $self->open($opts) if $opts->{open};
    return $self;
}

# Closes both input and output
sub close($)
{
    my $self = shift;
    $self->{state} = 'closing';
    if ($self->{inout}) {
	$self->{inout}->shutdown(2);
	close($self->{inout}) 
    }
    $self->{state} = 'disconnected';
}

sub is_disconnected($)
{
    my $self = shift;
    return 'disconnected' eq $self->{state};
}

sub open($;$)
{
    my ($self, $opts) = @_;
    $opts = hash_merge($opts, CLIENT_SOCKET_OPTS);
    $self->{host} = $opts->{host};
    $self->{port} = $opts->{port};
    $self->{inout} = 
    	IO::Socket::INET->new(PeerAddr=> $self->{host},
    			      PeerPort => $self->{port},
    			      Proto    => 'tcp',
    			      Type     => SOCK_STREAM
    	);
    if ($self->{inout}) {
    	$self->{state} = 'connected';
    } else {
    	my $msg = sprintf("Open client for host %s on port %s gives error: %s", 
    			  $self->{host}, $self->{port}, $EVAL_ERROR);
    	die $msg;
    }
}

sub is_empty($) 
{
    my($self) = @_;
    0 == length($self->{buf});
}
    
# Read one message unit. It's possible however that
# more than one message will be set in a receive, so we will
# have to buffer that for the next read.
# EOFError will be raised on EOF.
sub read_msg($)
{
    my($self) = @_;
    if ($self->{state} eq 'connected') {
	if (!$self->{buf} || is_empty($self)) {
	    $self->{inout}->recv($self->{buf}, TCP_MAX_PACKET);
	    if (is_empty($self)) {
		$self->close;
		$self->{state} = 'disconnected';
		die "EOF while reading on socket";
	    }
        }
	my $data;
        ($self->{buf}, $data) = unpack_msg($self->{buf});
        return $data;
    } else {
        die sprintf("read_msg called in state: %s.", $self->{state});
    }
}

sub have_term_readline($) 
{
    return 0;
}

# This method the debugger uses to write a message unit.
sub write($$)
{
    my ($self, $msg) = @_;
    # FIXME: do we have to check the size of msg and split output? 
    $self->{inout}->send(pack_msg($msg));
}

sub writeline($$)
{
    my ($self, $msg) = @_;
    $self->write($msg . "\n");
}

# Demo
unless (caller) {
     if (scalar @ARGV) {
	 # my $pid = fork();
	 #if ($pid) {
	     print "Connecting...\n";
	     my $client = Devel::Trepan::IO::TCPClient-> new({'open' => 1});
	     $client->writeline("Hi there\n");
	     # for (;;) {
	     # 	 undef $!;
	     # 	 my $line;
	     # 	 unless (defined( $line = <> )) {
	     # 	     if (eof) {
	     # 		 print "Got EOF\n";
	     # 		 last;
	     # 	     }
	     # 	     if ($!) {
	     # 		 print STDERR $!;
	     # 		 last;
	     # 	     }
	     # 	     chomp $line;
	     # 	     last if $line eq 'quit';
	     # 	     $line = $client->writeline($line);
	     # 	     # print "Got: #{client.read_msg.chomp}\n";
	     # 	 }
	     # }
	     $client->close;
	 #} else {
	     # server = TCPServer.new('localhost', 1027);
	     # session = server.accept;
	     # while 'quit' != (line = session.gets);
	     # session.puts line ;
	 #   exec "nc -l 1027";
	 # }
     }
}

1;
