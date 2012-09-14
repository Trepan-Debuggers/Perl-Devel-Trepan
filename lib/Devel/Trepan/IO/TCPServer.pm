# -*- coding: utf-8 -*-
# Copyright (C) 2011-2012 Rocky Bernstein <rocky@cpan.org>
# Debugger Server Input/Output interface.

use warnings; use strict;

use rlib '../../..';

package Devel::Trepan::IO::TCPServer;

use English qw ( -no_match_vars );
use IO::Socket qw(SOCK_STREAM);

use Devel::Trepan::IO::TCPPack;
use Devel::Trepan::Util qw(hash_merge);

use constant DEFAULT_INIT_OPTS => {open => 1};

use constant SERVER_SOCKET_OPTS => {
    host    => 'localhost',
    port    => 1954,
    timeout => 5,     # FIXME: not used
    reuse   => 1,     # FIXME: not used. Allow port to be resued on close?
    open    => 1,
    logger  => undef  # Complaints should be sent here.
    # Python has: 'posix' == os.name 
};

sub new($;$)
{
    my ($class, $opts) = @_;
    $opts    = hash_merge($opts, DEFAULT_INIT_OPTS);
    my $self = {
        input     => undef,
        output    => undef,
        session   => undef,
        buf       => '',    # Read buffer
        state     => 'disconnected',
        logger    => $opts->{logger},
        line_edit => 0
    };
    bless $self, $class;
    $self->open($opts) if $opts->{open};
    return $self;
}

sub is_connected($)
{
    my $self = shift;
    $self->{state} = 'connected' if 
        $self->{inout} and $self->{inout}->connected;
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
sub close
{
    my $self = shift;
    $self->{state} = 'closing';
    if ($self->{inout}) {
        close($self->{inout}) ;
    }
    $self->{state} = 'disconnected';
    print "FOOO\n";
    print {$self->{logger}} "Disconnected\n" if $self->{logger};
}

sub open($;$)
{
    my ($self, $opts) = @_;
    $opts = hash_merge($opts, SERVER_SOCKET_OPTS);
    $self->{host} = $opts->{host};
    $self->{port} = $opts->{port};
    $self->{server} = 
        IO::Socket::INET->new(
            LocalPort => $self->{port},
            LocalAddr => $self->{host},
            Type      => SOCK_STREAM,
            Reuse     => 1,
            Listen    => 1  # or SOMAXCONN
        );
    # @server.setsockopt(Socket::SOL_SOCKET, Socket::SO_RCVTIMEO, 5)
    #                   # @opts[:timeout])
    $self->{state} = 'listening';
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
    $self->wait_for_connect unless $self->is_connected;
    my ($buf, $data, $info);
    while (!$self->{buf} || is_empty($self)) { 
        $self->{session}->recv($self->{buf}, TCP_MAX_PACKET);
    }
    eval {
        ($self->{buf}, $data) = unpack_msg($self->{buf});
    };
    if ($EVAL_ERROR) {
        $self->{buf} = '';
        die $EVAL_ERROR;
    }
    return $data;
}

sub wait_for_connect
{
    my($self) = @_;
    if ($self->{logger}) {
        my $msg = sprintf("Waiting for a connection on port %d at " . 
                          "address %s...",
                          $self->{port}, $self->{host});
        print {$self->{logger}} "$msg\n";
    }
    $self->{input} = $self->{output} = $self->{session} = 
        $self->{server}->accept;
    print {$self->{logger}} "Got connection\n" if $self->{logger};
    $self->{state} = 'connected';
}
    
# This method the debugger uses to write. In contrast to
# writeline, no newline is added to the } to `str'. Also
# msg doesn't have to be a string.
sub write($$)
{
    my($self, $msg) = @_;
    $self->wait_for_connect unless $self->is_connected;
    # FIXME: do we have to check the size of msg and split output? 
    $self->{session}->print(pack_msg($msg));
}

sub writeline($$)
{
    my($self, $msg) = @_;
    $self->write($msg . "\n");
}

# Demo
unless (caller) {
  my $server = Devel::Trepan::IO::TCPServer->new(
      { open => 1,
        port => 1027,
      });
if (scalar @ARGV) {
    printf "Listening for connection...\n";
    my $line = $server->read_msg;
    while (defined($line)) {
        chomp $line;
        print "Got: $line\n";
        last if $line eq 'quit';
        $line = $server->read_msg;
    }
    # $server->open;
    # Thread.new do
    #   while 1 do
    #     begin
    #       line = server.read_msg.chomp
    #       puts "got #{line}"
    #     rescue EOFError
    #       puts 'Got EOF'
    #       break
    #     }
    #   }
    # }
    # threads << Thread.new do 
    #   t = TCPSocket.new('localhost', 1027)
    #   while 1 do
    #     begin
    #       print "input? "
    #       line = STDIN.gets
    #       break if !line || line.chomp == 'quit'
    #       t.puts(pack_msg(line))
    #     rescue EOFError
    #       puts "Got EOF"
    #       break
    #     rescue Exception => e
    #       puts "Got #{e}"
    #       break
    #     }
    #   }
    #   t.close
    # }
    # threads.each {|t| t.join }
    $server->close;
  }
}

1;
