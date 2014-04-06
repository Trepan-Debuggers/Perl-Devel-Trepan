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
    open    => 1,
    logger  => undef,  # Complaints should be sent here.
};

sub open($;$);

sub new($;$)
{
    my ($class, $opts) = @_;
    $opts    = hash_merge($opts, DEFAULT_INIT_OPTS);
    my $self = {
        input       => $opts->{input},
        line_edit => 0, # Our name for GNU readline capability
        logger      => $opts->{logger},
        output      => $opts->{output},
        state       => 'uninit',
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
    print {$self->{logger}} "Disconnected tty client\n" if $self->{logger};
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

    my $inpty_name = $opts->{inpty_name};
    $self->{input}  ||= $opts->{input};
    unless ($self->{input}) {
	if ($inpty_name) {
	    CORE::open($self->{input}, "<", $inpty_name) ||
		die "Can't open client input pty for reading: $!";
	} else {
	    $self->{input} = new IO::Pty;
	}
    }

    my $outpty_name = $opts->{outpty_name};
    $self->{output} ||= $opts->{output};
    unless ($self->{output}) {
	if ($outpty_name) {
	    CORE::open($self->{output}, ">", $outpty_name) ||
		die "Can't open client output pty for writing: $!";
	} else {
	    $self->{output} = new IO::Pty;
	}
    }

    if ($self->{logger}) {
	$inpty_name  ||= $self->{input}->ttyname();
	$outpty_name ||= $self->{output}->ttyname();
	my $msg = sprintf("input slave %s; output slave %s",
			  $inpty_name, $outpty_name);
	print {$self->{logger}} "$msg\n";
    }

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
    until ($msg) {
	$msg = <$fh>;
	chomp $msg if $msg;
    };
    return unpack_msg($msg);
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
    my $client = __PACKAGE__-> new({'open' => 1, logger => *STDOUT});
    if (scalar @ARGV) {
	require Devel::Trepan::IO::TTYServer;
	my $pid = fork();
	if ($pid) {
	    print "client pid $$...\n";
	    print "client before read\n";
	    my $msg = $client->read_msg();
	    print "client read from server message: $msg\n";
	    $client->writeline("client to server");
	    print "client before second read\n";
	    $msg = $client->read_msg();
	    print "client read from server message: $msg\n";
	    print "client $$ is done but waiting on server $pid\n";
	    waitpid($pid, 0);
	    $client->close();
	    print "client is leaving\n";
	} else {
	    print "server pid $$...\n";
	    require Devel::Trepan::IO::TTYServer;
	     # Server's input goes to client's output and vice versa
	    my $server = Devel::Trepan::IO::TTYServer->new(
		 {'open'=> 1,
		  'input'  => $client->{output}->slave,
		  'output' => $client->{input}->slave,
		  'logger' => *STDOUT
		 });
	    print "server before write\n";
	    $server->writeline("server to client");
	    print "server before read\n";
	    my $msg = $server->read_msg();
	    print "server read from client message: $msg\n";
	    print "server before second write\n";
	    $server->write("server to client nocr");
	    sleep(1);
	    print "server is leaving\n";
	    $server->close();
	}
    } else {
	my $client = __PACKAGE__->new({'open' => 1});
	$client->close();
    }
}

1;
